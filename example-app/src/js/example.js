import { BrotherPrint } from 'brother-print';

window.base64Print = async () => {
  const deviceIdentifier = document.getElementById("deviceIdentifier").value;
  const printMethod = document.getElementById("printMethod").value;
  const labelType = parseInt(document.getElementById("labelType").value, 10);
  try {
    let res = await BrotherPrint.base64Print({
      printMethod: printMethod,
      deviceIdentifier: deviceIdentifier,
      labelType: labelType,
      base64Image: 'iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sosXVTvbc6RHirr2reNy1OXd6pJsQ+gqjk8VWFYmHrwBzW/n+uMPFiRwHB2I7ih8ciHFxIkd/3Omk5tCDV1t+2nNu5sxxpDFNx+huNhVT3/zMDz8usXC3ddaHBj1GHj/As08fwTS7Kt1HBTmyN29vdwAw+/wbwLVOJ3uAD1wi/dUH7Qei66PfyuRj4Ik9is+hglfbkbfR3cnZm7chlUWLdwmprtCohX4HUtlOcQjLYCu+fzGJH2QRKvP3UNz8bWk1qMxjGTOMThZ3kvgLI5AzFfo379UAAAAASUVORK5CYII=',
    });
  } catch (error) {
    console.error('Print failed', error);
  }
}

window.searchWifiPrinters = async () => {
  try {
    const result = await BrotherPrint.searchWifiPrinters();
    if (result.printers.length > 0) {
      document.getElementById("deviceIdentifier").value = result.printers[0];
    }
    console.log('Available Printers:', result.printers);
  } catch (error) {
    console.error('Error searching for printers:', error);
  }
}

window.searchBluetoothPrinters = async () => {
  try {
    const result = await BrotherPrint.searchBluetoothPrinters();
    if (result.printers.length > 0) {
      document.getElementById("deviceIdentifier").value = result.printers[0];
    }
    console.log('Available Printers:', result.printers);
  } catch (error) {
    console.error('Error searching for printers:', error);
  }
}

window.checkPrinterStatus = async () => {
  const deviceIdentifier = document.getElementById("deviceIdentifier").value;
  const printMethod = document.getElementById("printMethod").value;
  try {
    const result = await BrotherPrint.checkPrinterStatus({
      deviceIdentifier: deviceIdentifier,
      printMethod: printMethod,
    });
    console.log('Printer Status:', result);
  } catch (error) {
    console.error('Error checking printer status:', error);
  }
}