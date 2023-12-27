// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import './Processador.sol';
import './Autoritat.sol';

// Contracte dels sensors
contract Sensors {

    // --------------------------------------------------------- DECLACACIONS INICIALS ---------------------------------------------------------
    
    Autoritat private autor;
    Processador private process;


    // Constructor del contracte
    constructor (address _aProcessador, address _aAutoritat) {
        process = Processador(_aProcessador);
        autor = Autoritat(_aAutoritat);
    }

    
    // --------------------------------------------------------- MODIFIERS ---------------------------------------------------------

    // Només pels sensors registrats
    modifier onlyBySensors(address _account) {
        require(
            autor.sensorValid(_account),
            "Nomes sensors registrats"
        );
        _;
    }



    // --------------------------------------------------------- FUNCTIONS ---------------------------------------------------------

    ///// REGISTRA DE TEMPERATURES /////

    function registraTemperaturaSensor(int16 _valor) public onlyBySensors(msg.sender){
        process.registraTemperatura(msg.sender, _valor);
    }
    
}