import { BrotherPrint } from 'brother-print';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    BrotherPrint.echo({ value: inputValue })
}
