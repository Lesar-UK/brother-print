package dev.kieranbarlow.plugins.brotherprint;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Build;
import android.util.Base64;
import androidx.core.content.ContextCompat;
import com.brother.sdk.lmprinter.Channel;
import com.brother.sdk.lmprinter.GetStatusResult;
import com.brother.sdk.lmprinter.NetworkSearchOption;
import com.brother.sdk.lmprinter.OpenChannelError;
import com.brother.sdk.lmprinter.PrintError;
import com.brother.sdk.lmprinter.PrinterDriver;
import com.brother.sdk.lmprinter.PrinterDriverGenerateResult;
import com.brother.sdk.lmprinter.PrinterDriverGenerator;
import com.brother.sdk.lmprinter.PrinterModel;
import com.brother.sdk.lmprinter.PrinterSearchResult;
import com.brother.sdk.lmprinter.PrinterSearcher;
import com.brother.sdk.lmprinter.PrinterStatus;
import com.brother.sdk.lmprinter.setting.PrintImageSettings;
import com.brother.sdk.lmprinter.setting.QLPrintSettings;
import com.getcapacitor.JSArray;
import com.getcapacitor.PluginCall;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.regex.Pattern;

public class BrotherPrintSDK {

    private static final Pattern BLUETOOTH_MAC_ADDRESS = Pattern.compile("(?i)^([0-9a-f]{2}:){5}[0-9a-f]{2}$");

    public JSArray searchWifiPrinters(Context context) {
        JSArray printers = new JSArray();
        NetworkSearchOption option = new NetworkSearchOption(15, false);
        PrinterSearchResult result = PrinterSearcher.startNetworkSearch(context, option, (channel) ->
            printers.put(channel.getChannelInfo())
        );

        if (result.getError() != null && result.getError().getCode() != null) {
            String code = result.getError().getCode().name();
            if (!"NoError".equals(code)) {
                throw new IllegalStateException("Wi-Fi search failed: " + code);
            }
        }

        return printers;
    }

    public JSArray searchBluetoothPrinters(Context context) {
        ensureBluetoothPermissions(context);

        JSArray printers = new JSArray();
        PrinterSearchResult result = PrinterSearcher.startBluetoothSearch(context);

        if (result.getError() != null && result.getError().getCode() != null) {
            String code = result.getError().getCode().name();
            if (!"NoError".equals(code)) {
                throw new IllegalStateException("Bluetooth search failed: " + code);
            }
        }

        if (result.getChannels() == null) {
            return printers;
        }

        for (Channel channel : result.getChannels()) {
            String serialNumber = getChannelExtraInfo(channel, Channel.ExtraInfoKey.SerialNubmer);
            printers.put(firstNonEmpty(serialNumber, channel.getChannelInfo()));
        }

        return printers;
    }

    public String printImage(Context context, PluginCall call) throws IOException {
        PrintJobSpec spec = buildSpec(call);
        File imageFile = writeImageTempFile(context, spec.base64String);
        try {
            return withDriver(spec, context, (driver) -> {
                PrintError error = driver.printImage(imageFile.getAbsolutePath(), buildQlSettings(context, spec, driver, imageFile));
                throwIfPrintFailed(error);
                return "Printed image successfully";
            });
        } finally {
            deleteTempFile(imageFile);
        }
    }

    public String printPDF(Context context, PluginCall call) throws IOException {
        PrintJobSpec spec = buildSpec(call);
        File pdfFile = writeTempFile(context, spec.base64String, "passprinter-", ".pdf");
        try {
            return withDriver(spec, context, (driver) -> {
                PrintError error = driver.printPDF(pdfFile.getAbsolutePath(), buildQlSettings(context, spec, driver, null));
                throwIfPrintFailed(error);
                return "Printed PDF successfully";
            });
        } finally {
            deleteTempFile(pdfFile);
        }
    }

    public JSArray checkPrinterStatus(Context context, PluginCall call) {
        PrintJobSpec spec = buildSpec(call);
        return withDriver(spec, context, (driver) -> {
            GetStatusResult result = driver.getPrinterStatus();
            if (result.getError() != null && result.getError().getCode() != null) {
                String code = result.getError().getCode().name();
                if (!"NoError".equals(code)) {
                    throw new IllegalStateException("Status request failed: " + code);
                }
            }

            JSArray status = new JSArray();
            PrinterStatus printerStatus = result.getPrinterStatus();
            if (printerStatus == null) {
                return status;
            }

            if (printerStatus.getModel() != null) {
                status.put("model:" + printerStatus.getModel().name());
            }
            if (printerStatus.getErrorCode() != null) {
                status.put("error:" + printerStatus.getErrorCode().name());
            }
            if (printerStatus.getMediaInfo() != null) {
                status.put("media:" + printerStatus.getMediaInfo().toString());
            }
            if (printerStatus.getBatteryStatus() != null) {
                status.put("battery:" + printerStatus.getBatteryStatus().toString());
            }

            return status;
        });
    }

    public void ensureBluetoothPermissions(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ensurePermission(context, Manifest.permission.BLUETOOTH_CONNECT, "BLUETOOTH_CONNECT");
            ensurePermission(context, Manifest.permission.BLUETOOTH_SCAN, "BLUETOOTH_SCAN");
            return;
        }

        ensurePermission(context, Manifest.permission.ACCESS_FINE_LOCATION, "ACCESS_FINE_LOCATION");
    }

    private void ensurePermission(Context context, String permission, String label) {
        if (ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
            throw new IllegalStateException(label + " permission is required before using Brother Bluetooth features.");
        }
    }

    private PrintJobSpec buildSpec(PluginCall call) {
        String printMethod = call.getString("printMethod", "wifi");
        String deviceIdentifier = call.getString("deviceIdentifier");
        String base64String = call.getString("base64String", "");
        String model = call.getString("model", "QL-820NWB");
        Integer labelSize = call.getInt("labelSize", 62);

        if (deviceIdentifier == null || deviceIdentifier.isEmpty()) {
            throw new IllegalArgumentException("deviceIdentifier is required.");
        }

        return new PrintJobSpec(printMethod, deviceIdentifier, base64String, model, labelSize);
    }

    private Channel createChannel(Context context, PrintJobSpec spec) {
        if ("bluetooth".equalsIgnoreCase(spec.printMethod)) {
            BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
            BluetoothAdapter adapter = bluetoothManager != null ? bluetoothManager.getAdapter() : BluetoothAdapter.getDefaultAdapter();
            if (adapter == null) {
                throw new IllegalStateException("Bluetooth adapter is unavailable.");
            }
            return Channel.newBluetoothChannel(resolveBluetoothAddress(context, spec.deviceIdentifier), adapter);
        }

        return Channel.newWifiChannel(spec.deviceIdentifier);
    }

    private QLPrintSettings buildQlSettings(Context context, PrintJobSpec spec, PrinterDriver driver, File imageFile) {
        QLPrintSettings settings = new QLPrintSettings(mapModel(spec.model));
        settings.setLabelSize(resolveLabelSize(driver, spec));
        settings.setAutoCut(true);
        settings.setCutAtEnd(true);
        settings.setHalftone(PrintImageSettings.Halftone.ErrorDiffusion);
        settings.setCompress(PrintImageSettings.CompressMode.None);
        settings.setPrintQuality(PrintImageSettings.PrintQuality.Best);
        settings.setBiColorRedEnhancement(20);
        settings.setBiColorGreenEnhancement(0);
        settings.setBiColorBlueEnhancement(0);
        settings.setWorkPath(context.getCacheDir().getAbsolutePath());
        applyImageOrientation(settings, imageFile);
        return settings;
    }

    private void applyImageOrientation(QLPrintSettings settings, File imageFile) {
        if (imageFile == null) {
            return;
        }

        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(imageFile.getAbsolutePath(), options);

        if (options.outWidth <= 0 || options.outHeight <= 0) {
            return;
        }

        PrintImageSettings.Orientation orientation =
            options.outWidth > options.outHeight ? PrintImageSettings.Orientation.Landscape : PrintImageSettings.Orientation.Portrait;

        settings.setPrintOrientation(orientation);
    }

    private QLPrintSettings.LabelSize resolveLabelSize(PrinterDriver driver, PrintJobSpec spec) {
        try {
            GetStatusResult result = driver.getPrinterStatus();
            if (
                result != null &&
                result.getError() != null &&
                result.getError().getCode() != null &&
                "NoError".equals(result.getError().getCode().name()) &&
                result.getPrinterStatus() != null &&
                result.getPrinterStatus().getMediaInfo() != null &&
                result.getPrinterStatus().getMediaInfo().getQLLabelSize() != null
            ) {
                return result.getPrinterStatus().getMediaInfo().getQLLabelSize();
            }
        } catch (Exception ignored) {
            // Fall back to the configured label size when status/media detection is unavailable.
        }

        return mapLabelSize(spec.labelSize);
    }

    private PrinterModel mapModel(String model) {
        switch (model) {
            case "QL-810W":
                return PrinterModel.QL_810W;
            case "QL-820NWB":
            default:
                return PrinterModel.QL_820NWB;
        }
    }

    private QLPrintSettings.LabelSize mapLabelSize(Integer labelSize) {
        if (labelSize == null) {
            return QLPrintSettings.LabelSize.RollW62;
        }

        switch (labelSize) {
            case 12:
                return QLPrintSettings.LabelSize.RollW12;
            case 29:
                return QLPrintSettings.LabelSize.RollW29;
            case 38:
                return QLPrintSettings.LabelSize.RollW38;
            case 50:
                return QLPrintSettings.LabelSize.RollW50;
            case 54:
                return QLPrintSettings.LabelSize.RollW54;
            case 62:
            default:
                return QLPrintSettings.LabelSize.RollW62;
        }
    }

    private String resolveBluetoothAddress(Context context, String deviceIdentifier) {
        if (BLUETOOTH_MAC_ADDRESS.matcher(deviceIdentifier).matches()) {
            return deviceIdentifier;
        }

        ensureBluetoothPermissions(context);
        PrinterSearchResult result = PrinterSearcher.startBluetoothSearch(context);
        if (result.getChannels() == null) {
            throw new IllegalArgumentException("Bluetooth printer not found for identifier: " + deviceIdentifier);
        }

        for (Channel channel : result.getChannels()) {
            String channelInfo = channel.getChannelInfo();
            String serialNumber = getChannelExtraInfo(channel, Channel.ExtraInfoKey.SerialNubmer);
            String macAddress = getChannelExtraInfo(channel, Channel.ExtraInfoKey.MACAddress);
            String bluetoothAlias = getChannelExtraInfo(channel, Channel.ExtraInfoKey.BluetoothAlias);

            if (
                equalsIgnoreCase(deviceIdentifier, serialNumber) ||
                equalsIgnoreCase(deviceIdentifier, channelInfo) ||
                equalsIgnoreCase(deviceIdentifier, macAddress) ||
                equalsIgnoreCase(deviceIdentifier, bluetoothAlias)
            ) {
                return firstNonEmpty(macAddress, channelInfo);
            }
        }

        throw new IllegalArgumentException("Bluetooth printer not found for identifier: " + deviceIdentifier);
    }

    private String getChannelExtraInfo(Channel channel, Channel.ExtraInfoKey key) {
        HashMap<Channel.ExtraInfoKey, String> extraInfo = channel.getExtraInfo();
        if (extraInfo == null) {
            return null;
        }

        return extraInfo.get(key);
    }

    private boolean equalsIgnoreCase(String left, String right) {
        return left != null && right != null && left.equalsIgnoreCase(right);
    }

    private String firstNonEmpty(String first, String second) {
        if (first != null && !first.isEmpty()) {
            return first;
        }

        return second;
    }

    private File writeImageTempFile(Context context, String base64String) throws IOException {
        byte[] bytes = decodeBase64(base64String);
        Bitmap source = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        if (source == null) {
            throw new IllegalArgumentException("base64String must be a valid image.");
        }

        Bitmap flattened = Bitmap.createBitmap(source.getWidth(), source.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(flattened);
        canvas.drawColor(Color.WHITE);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG | Paint.FILTER_BITMAP_FLAG);
        canvas.drawBitmap(source, 0, 0, paint);

        File file = File.createTempFile("passprinter-", ".png", context.getCacheDir());
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            flattened.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
            outputStream.flush();
        } finally {
            source.recycle();
            flattened.recycle();
        }

        return file;
    }

    private File writeTempFile(Context context, String base64String, String prefix, String suffix) throws IOException {
        byte[] bytes = decodeBase64(base64String);
        File file = File.createTempFile(prefix, suffix, context.getCacheDir());
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            outputStream.write(bytes);
            outputStream.flush();
        }
        return file;
    }

    private byte[] decodeBase64(String base64String) {
        if (base64String == null || base64String.isEmpty()) {
            throw new IllegalArgumentException("base64String is required.");
        }

        String normalized = base64String;
        int commaIndex = normalized.indexOf(',');
        if (commaIndex >= 0) {
            normalized = normalized.substring(commaIndex + 1);
        }

        return Base64.decode(normalized, Base64.DEFAULT);
    }

    private void deleteTempFile(File file) {
        if (file != null && file.exists()) {
            file.delete();
        }
    }

    private void throwIfPrintFailed(PrintError error) {
        if (error == null || error.getCode() == null) {
            throw new IllegalStateException("Brother SDK returned an unknown print result.");
        }

        if (error.getCode() != PrintError.ErrorCode.NoError) {
            String description = error.getErrorDescription() != null ? error.getErrorDescription() : "";
            throw new IllegalStateException("Print failed: " + error.getCode().name() + " " + description);
        }
    }

    private <T> T withDriver(PrintJobSpec spec, Context context, DriverOperation<T> operation) {
        Channel channel = createChannel(context, spec);
        PrinterDriverGenerateResult result = PrinterDriverGenerator.openChannel(channel);

        if (result.getError() != null && result.getError().getCode() != OpenChannelError.ErrorCode.NoError) {
            throw new IllegalStateException("Open channel failed: " + result.getError().getCode().name());
        }

        PrinterDriver driver = result.getDriver();
        if (driver == null) {
            throw new IllegalStateException("Brother SDK did not return a printer driver.");
        }

        try {
            return operation.run(driver);
        } finally {
            driver.closeChannel();
        }
    }

    private interface DriverOperation<T> {
        T run(PrinterDriver driver);
    }

    private static class PrintJobSpec {

        final String printMethod;
        final String deviceIdentifier;
        final String base64String;
        final String model;
        final Integer labelSize;

        PrintJobSpec(String printMethod, String deviceIdentifier, String base64String, String model, Integer labelSize) {
            this.printMethod = printMethod;
            this.deviceIdentifier = deviceIdentifier;
            this.base64String = base64String;
            this.model = model;
            this.labelSize = labelSize;
        }
    }
}
