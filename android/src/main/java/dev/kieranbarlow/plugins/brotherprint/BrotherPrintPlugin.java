package dev.kieranbarlow.plugins.brotherprint;

import android.Manifest;
import android.os.Build;
import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

@CapacitorPlugin(
    name = "BrotherPrint",
    permissions = {
        @Permission(
            strings = { Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.BLUETOOTH_CONNECT },
            alias = "bluetooth"
        ),
        @Permission(strings = { Manifest.permission.ACCESS_FINE_LOCATION }, alias = "location"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_SCAN }, alias = "bluetoothScan")
    }
)
public class BrotherPrintPlugin extends Plugin {

    private final BrotherPrintSDK implementation = new BrotherPrintSDK();

    @PluginMethod
    public void searchWifiPrinters(PluginCall call) {
        try {
            JSObject ret = new JSObject();
            ret.put("printers", implementation.searchWifiPrinters(getContext()));
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void searchBluetoothPrinters(PluginCall call) {
        if (!ensureBluetoothPermissions(call, "searchBluetoothPrintersPermsCallback")) {
            return;
        }

        try {
            JSObject ret = new JSObject();
            ret.put("printers", implementation.searchBluetoothPrinters(getContext()));
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void printImage(PluginCall call) {
        if (isBluetoothCall(call) && !ensureBluetoothPermissions(call, "printImagePermsCallback")) {
            return;
        }

        try {
            String message = implementation.printImage(getContext(), call);
            JSObject ret = new JSObject();
            ret.put("message", message);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void printPDF(PluginCall call) {
        if (isBluetoothCall(call) && !ensureBluetoothPermissions(call, "printPDFPermsCallback")) {
            return;
        }

        try {
            String message = implementation.printPDF(getContext(), call);
            JSObject ret = new JSObject();
            ret.put("message", message);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void checkPrinterStatus(PluginCall call) {
        if (isBluetoothCall(call) && !ensureBluetoothPermissions(call, "checkPrinterStatusPermsCallback")) {
            return;
        }

        try {
            JSObject ret = new JSObject();
            ret.put("status", implementation.checkPrinterStatus(getContext(), call));
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    private boolean isBluetoothCall(PluginCall call) {
        String printMethod = call.getString("printMethod", "wifi");
        return "bluetooth".equalsIgnoreCase(printMethod);
    }

    private boolean ensureBluetoothPermissions(PluginCall call, String callbackName) {
        if (hasBluetoothPermissions()) {
            return true;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissionForAliases(new String[] { "bluetooth", "bluetoothScan" }, call, callbackName);
        } else {
            requestPermissionForAlias("location", call, callbackName);
        }
        return false;
    }

    private boolean hasBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return (
                getPermissionState("bluetooth") == PermissionState.GRANTED && getPermissionState("bluetoothScan") == PermissionState.GRANTED
            );
        }

        return getPermissionState("location") == PermissionState.GRANTED;
    }

    @PermissionCallback
    private void searchBluetoothPrintersPermsCallback(PluginCall call) {
        if (!hasBluetoothPermissions()) {
            call.reject("Bluetooth permissions are required before using Brother Bluetooth features.");
            return;
        }
        searchBluetoothPrinters(call);
    }

    @PermissionCallback
    private void printImagePermsCallback(PluginCall call) {
        if (!hasBluetoothPermissions()) {
            call.reject("Bluetooth permissions are required before using Brother Bluetooth features.");
            return;
        }
        printImage(call);
    }

    @PermissionCallback
    private void printPDFPermsCallback(PluginCall call) {
        if (!hasBluetoothPermissions()) {
            call.reject("Bluetooth permissions are required before using Brother Bluetooth features.");
            return;
        }
        printPDF(call);
    }

    @PermissionCallback
    private void checkPrinterStatusPermsCallback(PluginCall call) {
        if (!hasBluetoothPermissions()) {
            call.reject("Bluetooth permissions are required before using Brother Bluetooth features.");
            return;
        }
        checkPrinterStatus(call);
    }
}
