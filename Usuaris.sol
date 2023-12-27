// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import './Processador.sol';
import './Farmacia.sol';

// Contracte dels usuaris
contract Usuaris {

    // --------------------------------------------------------- DECLACACIONS INICIALS ---------------------------------------------------------
    
    Farmacia private farm;
    Processador private process;


    // Constructor del contracte
    constructor (address _aProcessador, address _aFarmacia) {
        process = Processador(_aProcessador);
        farm = Farmacia(_aFarmacia);
    }

    
    // --------------------------------------------------------- MODIFIERS ---------------------------------------------------------

    // Només pels usuaris registrats
    modifier onlyByUsuaris(address _account) {
        require(
            farm.usuariValid(_account),
            "Nomes usuaris registrats"
        );
        _;
    }



    // --------------------------------------------------------- FUNCTIONS ---------------------------------------------------------

    ///// VISUALITZACIÓ DE TEMPERATURES /////

   function elsMeusSensors() public view onlyByUsuaris(msg.sender) returns(address[] memory adrecesSensors){
        (uint[] memory auxIdAssociacions, ) = process.visualitzaAssociacionsUsuari(msg.sender);
        address[] memory auxSensors = new address[](auxIdAssociacions.length);
        for(uint i = 0; i < auxIdAssociacions.length; i++){
            auxSensors[i] = process.sensorAssociacio(auxIdAssociacions[i]);
        }
        
        return auxSensors;
    }
    
    
    function lesMevesAssociacionsActuals() public view onlyByUsuaris(msg.sender) returns(uint[] memory idAssociacions, uint[] memory dataAssociacions){
        return process.visualitzaAssociacionsUsuari(msg.sender);
    }
    
    
    function visualitzaNotificacioNoVista() public onlyByUsuaris(msg.sender) returns (uint dataNotificacio, uint idAssociacio) { 
        return process.visualitzaNotificacioNoVista(msg.sender);
    }
    

    function visualitzaUnCicle(uint _idAssociacio) public view onlyByUsuaris(msg.sender) returns(uint[] memory dataTemperatura, int16[] memory valorTemperatura){
        return process.getRegistresUsuari(_idAssociacio, msg.sender);
    }
    
}