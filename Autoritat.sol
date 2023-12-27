// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

// Contracte de l'autoritat
contract Autoritat {

    // --------------------------------------------------------- DECLACACIONS INICIALS ---------------------------------------------------------
    
    address private owner;
    address private aProcessador;
    address private aFarmacia;
    address private aSensors;

    enum estatActor {baixa, alta}

    // Constructor del contracte
    constructor (address _aOwner, address _aProcess) {
        owner = _aOwner;
        aProcessador = _aProcess;
    }
   
    // Estructura de farmacèutics
    struct Farmaceutic {
        estatActor estat;
    }

    // Estructura de sensors
    struct Sensor {
        estatActor estat;
    }


    // Mapping per obtenir les dades d'un farmecèutic amb la seva adreça
    mapping(address => Farmaceutic) private farmaceuticsMap;

    // Mapping per obtenir les dades d'un sensor amb la seva adreça
    mapping(address => Sensor) private sensorsMap;



    // --------------------------------------------------------- MODIFIERS ---------------------------------------------------------

    // Només l'adreça de l'autoritat
    modifier onlyByAutoritat(address _account) {
        require(
            _account == owner,             
            "Nomes autoritat"
        );
        _;
    }

    // Només l'adreça dels contractes desplegats
    modifier onlyByContractes(address _account) {
        require(
            (_account == aProcessador) || (_account == aFarmacia) || (_account == aSensors),             
            "Nomes els contractes desplegats"
        );
        _;
    }



    // --------------------------------------------------------- FUNCTIONS ---------------------------------------------------------

    ///// GESTIÓ FARMACÈUTICS /////

    function registraFarmaceutic(address _aFarmaceutic) public onlyByAutoritat(msg.sender){
        Farmaceutic memory f;
        f.estat = estatActor.alta;
        farmaceuticsMap[_aFarmaceutic] = f; 
    }


    function baixaFarmaceutic(address _aFarmaceutic) public onlyByAutoritat(msg.sender){
        require(farmaceuticsMap[_aFarmaceutic].estat == estatActor.alta, "Farmaceutic no te estat \"alta\"");
        farmaceuticsMap[_aFarmaceutic].estat = estatActor.baixa;
    }


    function farmaceuticValid(address _account) public view onlyByContractes(msg.sender) returns(bool farmaceuticIsValid){
        if (farmaceuticsMap[_account].estat == estatActor.alta) {
            return true;
        } else {
            return false;
        }
    }



    ///// GESTIÓ SENSORS /////

    function registraSensor(address _aSensor) public onlyByAutoritat(msg.sender){
        Sensor memory s;
        s.estat = estatActor.alta;
        sensorsMap[_aSensor] = s;
    }


    function baixaSensor(address _aSensor) public onlyByAutoritat(msg.sender){
        require(sensorsMap[_aSensor].estat == estatActor.alta, "Sensor no te estat \"alta\"");
        sensorsMap[_aSensor].estat = estatActor.baixa;
    }


    function sensorValid(address _account) public view onlyByContractes(msg.sender) returns(bool sensorIsValid){
        if (sensorsMap[_account].estat == estatActor.alta) {
            return true;
        } else {
            return false;
        }
    }



    ///// REBRE ADREÇES D'ALTRES SC //////

    function rebreAddressContractes(address _aSensors, address _aFarmacia) public onlyByContractes(msg.sender) {
        aSensors = _aSensors;
        aFarmacia = _aFarmacia;
    }
    
}