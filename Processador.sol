// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20 <0.9.0;

import './Autoritat.sol';
import './Farmacia.sol';
import './Sensors.sol';
import './Usuaris.sol';

// Contracte processador d'informació. Aquí es guarden i processen les dades, i es despleguen la resta de contractes
contract Processador {

    // --------------------------------------------------------- DECLACACIONS INICIALS ---------------------------------------------------------
    
    address private Owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // Canviar per l'adreça real de l'autoritat
    
    address private aProcessador;
    address private aAutoritat;
    address private aFarmacia;
    address private aSensors;
    address private aUsuaris;

    Autoritat private autor;
    Sensors private sens;
    Farmacia private farm;

    uint private totalRegistres;
    uint private totalAssociacions;
    uint private totalNotificacions;

    bool private contractesDesplegats = false;


    // Constructor del contracte
    constructor() {
        aProcessador = address(uint160(address(this)));
    }

    // Estructura dels medicaments
    struct Medicament { // idMedicament
        string nom;
        int16 minTemp;
        int16 maxTemp;
        uint16 numMaxRegistres;
    }

    // Estructura de registre
    struct Registre { // idRegistre
        uint data;
        address aSensor;
        int16 valorTemp;
    }

    // Estructura d'associacions usuari-sensors
    struct Associacio { // idAssociacio
        uint dataInici;
        uint dataFi;
        address aUsuari;
        address aSensor;
        uint ium;
        bool revocada;
    }

     // Estructura de notificació d'alerta a usuari
    struct Notificacio { // idAssociacio
        uint data;
        bool vista;
        uint idAssociacio;
    }


    // Mapping per obtenir les dades d'un medicament amb el seu identificador únic
    mapping(uint => Medicament) private medicamentsMap;

    // Mapping per obtenir les dades d'un registre de temperatura amb el seu identificacor
    mapping(uint => Registre) private registresMap;

    // Mapping per obtenir l'ID d'alerta d'un sensor
    mapping(address => uint[]) private registresDeSensor;

    // Mapping per obtenir una associació amb el seu identificador
    mapping(uint => Associacio) private associacionsMap;
    
    // Mapping per obtenir l'array d'associacions (sensors) a associats a un usuari
    mapping(address => uint[]) private associacionsDeUsuari;

    //Mapping per obtenir l'id d'associació actual d'un sensor
    mapping(address => uint) private associacioDeSensor;

    // Mapping per obtenir una notificació amb el seu identificador
    mapping(uint => Notificacio) private notificacionsMap;
    
    // Mapping per obtenir l'array de notificacions a un usuari
    mapping(address => uint[]) private notificacionsDeUsuari;
    


    // --------------------------------------------------------- MODIFIERS ---------------------------------------------------------

    // Només l'adreça de l'autoritat
    modifier onlyByAutoritat(address _account) {
        require(
            _account == Owner,             
            "Nomes autoritat"
        );
        _;
    }
    
    // Només les adreces dels contractes desplegats (Farmacia, Sensors i Usuaris)
    modifier onlyByContractes(address _account) {
        require(
            (_account == aFarmacia) || (_account == aSensors) || (_account == aUsuaris) || (_account == aProcessador),             
            "Nomes SC desplegats"
        );
        _;
    }



    // --------------------------------------------------------- FUNCTIONS ---------------------------------------------------------

    ///// FUNCIONS PER DESPLAGAR ALTRES CONTRACTES /////

    // Funció per iniciar tots els contractes d'una vegada
    function desplegaTotsElsSC() public onlyByAutoritat(msg.sender) returns (address addressAutoritat, address addressFarmacia, address addressSensors, address addressUsuaris){
        require(!contractesDesplegats, "Els contractes nomes es poden desplegar una vegada");
        
        // Autoritat
        autor = new Autoritat(Owner, aProcessador);
        aAutoritat = address(autor);

        // Sensors
        sens = new Sensors(aProcessador, aAutoritat);
        aSensors = address(sens);

        // Farmacia
        farm = new Farmacia(aProcessador, aAutoritat);
        aFarmacia = address(farm);

        // Usuaris
        Usuaris usu = new Usuaris(aProcessador, aFarmacia);
        aUsuaris = address(usu);
        
    
        
        //Enviar les adreces entre els diferents smart contracts perquè puguin interectuar
        autor.rebreAddressContractes(aSensors, aFarmacia);
        farm.rebreAddressContractes(aUsuaris);

        contractesDesplegats = true;
        

        return (aAutoritat, aFarmacia, aSensors, aUsuaris);
    }
    
    
    
    ///// GESTIÓ TEMPERATURES /////

    function registraTemperatura(address _aSensor, int16 _valor) public onlyByContractes(msg.sender){
        require(necessitatRegistrar(_aSensor, _valor), "La temperatura no esta dins del rang, o l'associacio ha expirat.");

        totalRegistres++;
        
        Registre memory r;
        r.data = block.timestamp;
        r.aSensor = _aSensor;
        r.valorTemp = _valor;
        registresMap[totalRegistres] = r;

        registresDeSensor[_aSensor].push(totalRegistres);

        processaTemperatura(_aSensor);
    }

    function necessitatRegistrar(address _aSensor, int16 _valor) private view returns(bool registrar){
        uint idAssociacio = associacioDeSensor[_aSensor];
        if ((associacionsMap[idAssociacio].dataFi > block.timestamp) && (!associacionsMap[idAssociacio].revocada)) {
            uint auxIum = associacionsMap[idAssociacio].ium;
            if((_valor > medicamentsMap[auxIum].minTemp) || (_valor < medicamentsMap[auxIum].maxTemp)) {
                return true;
            }
        }
        return false; // Altre cas
    }

    function processaTemperatura(address _aSensor) private {
        if(medicamentEnMalEstat(_aSensor)) {
            totalNotificacions++;
        
            Notificacio memory n;
            n.data = block.timestamp;
            n.vista = false;
            n.idAssociacio = associacioDeSensor[_aSensor];
            notificacionsMap[totalNotificacions] = n;

            notificacionsDeUsuari[associacionsMap[associacioDeSensor[_aSensor]].aUsuari].push(totalNotificacions);

            // Revocar associació
            associacionsMap[associacioDeSensor[_aSensor]].revocada = true;
        }
    }
    
    function medicamentEnMalEstat(address _aSensor) private view returns(bool medicamentenMalEstat){
        (uint auxRegistresAssociacio, , ) = getRegistres(_aSensor, associacionsMap[associacioDeSensor[_aSensor]].dataInici, associacionsMap[associacioDeSensor[_aSensor]].dataFi);
        
        if(auxRegistresAssociacio > medicamentsMap[associacionsMap[associacioDeSensor[_aSensor]].ium].numMaxRegistres) {
            return true;
        }

        return (false);
    }

    function visualitzaNotificacioNoVista(address _aUsuari) public onlyByContractes(msg.sender) returns (uint dataNotificacio, uint idAssociacio) { 
        (bool auxNotificacions, uint auxPosicio) = usuariTeNotificacions(_aUsuari);
        require (auxNotificacions, "No hi ha notificacions.");
        notificacionsMap[auxPosicio].vista = true;
        return (notificacionsMap[auxPosicio].data, notificacionsMap[auxPosicio].idAssociacio);
    }

    function usuariTeNotificacions(address _aUsuari) private view returns (bool teNotificacions, uint posicio) {
        uint[] memory auxIdNotificacions = notificacionsDeUsuari[_aUsuari];
        for (uint i = 0; i < auxIdNotificacions.length; i++) {
            if (!notificacionsMap[auxIdNotificacions[i]].vista) {
                return (true, auxIdNotificacions[i]);
            }
        }
        return (false, 0);
    }

    function getRegistresUsuari(uint _idAssociacio, address _aUsuari) public view onlyByContractes(msg.sender) returns (uint[] memory dataTemperatura, int16[] memory valorTemperatura) {
        require(associacionsMap[_idAssociacio].aUsuari == _aUsuari, "Nomes pots visualitzar les teves dades");

        uint auxDataIniciAssociacio = associacionsMap[_idAssociacio].dataInici;
        uint auxDataFiAssociacio = associacionsMap[_idAssociacio].dataFi;
        address auxASensor = associacionsMap[_idAssociacio].aSensor;

        (, uint[] memory auxData, int16[] memory auxValors) = getRegistres(auxASensor, auxDataIniciAssociacio, auxDataFiAssociacio);
        
        return (auxData, auxValors);
    }
    
    
    function getRegistres(address _aSensor, uint _start, uint _end) private view returns (uint totalTemperatures, uint[] memory dataTemperatura, int16[] memory valorTemperatura) {
        uint[] memory auxIdRegistres = registresDeSensor[_aSensor];
        uint[] memory auxRegistres = new uint[](auxIdRegistres.length);
        uint auxPosicio = 0;

        // Guardar posicions registres amb valor entre els dies
        for (uint i = 0; i < auxIdRegistres.length; i++) {
            uint auxData = registresMap[auxIdRegistres[i]].data;
            if (auxData >= _start && auxData <= _end) {
                auxRegistres[auxPosicio] = auxIdRegistres[i];
                auxPosicio++;
            }
        }

        // Retornar dates i valors de cada registre
        uint[] memory auxDataArray = new uint[](auxPosicio);
        int16[] memory temperaturaArray = new int16[](auxPosicio);
        for (uint i = 0; i < auxPosicio; i++) {
            auxDataArray[i] = registresMap[auxRegistres[i]].data;
            temperaturaArray[i] = registresMap[auxRegistres[i]].valorTemp;
        }

        return (auxPosicio, auxDataArray, temperaturaArray);
    }


    
    ///// GESTIÓ ASSOCIACIONS /////

    function registraAssociacio(address _aUsuari, address _aSensor, uint _ium, uint _dataFi) public onlyByContractes(msg.sender) returns(uint idAssociacio){
        require(block.timestamp < _dataFi, "Data finalitzacio incorrecte");
        require(farm.usuariValid(_aUsuari), "Usuari no registrat");
        require(autor.sensorValid(_aSensor), "Sensor no registrat");
        if(associacionsMap[associacioDeSensor[_aSensor]].dataFi > 0) {
            require(((associacionsMap[associacioDeSensor[_aSensor]].dataFi > block.timestamp) || (associacionsMap[associacioDeSensor[_aSensor]].revocada)), "Sensor actualment utilitzat");
        }
        require(bytes(medicamentsMap[_ium].nom).length > 1, "El medicament no existeix");
        
        totalAssociacions++;
        
        Associacio memory a;
        a.dataInici = block.timestamp;
        a.dataFi = _dataFi;
        a.aUsuari = _aUsuari;
        a.aSensor = _aSensor;
        a.ium = _ium;
        a.revocada = false;
        associacionsMap[totalAssociacions] = a;

        associacioDeSensor[_aSensor] = totalAssociacions;

        associacionsDeUsuari[_aUsuari].push(totalAssociacions);

        return totalAssociacions;
    }


    function baixaAssociacio(uint _idAssociacio) public onlyByContractes(msg.sender){
        require(!associacionsMap[_idAssociacio].revocada, "L'associacio no esta d'alta");
        associacionsMap[_idAssociacio].revocada = true;
    }


    function visualitzaAssociacionsUsuari(address _aUsuari) public view onlyByContractes(msg.sender) returns(uint[] memory idAssociacions, uint[] memory dataAssociacions){
        uint[] memory auxIdAssociacions = new uint[](associacionsDeUsuari[_aUsuari].length);
        uint auxPosicio = 0;

        // Filtrar les associacions actuals i no revocades
        for (uint i = 0; i < associacionsDeUsuari[_aUsuari].length; i++) {
            if (associacionsMap[associacionsDeUsuari[_aUsuari][i]].dataFi > block.timestamp && !associacionsMap[associacionsDeUsuari[_aUsuari][i]].revocada) {
                auxIdAssociacions[auxPosicio] = associacionsDeUsuari[_aUsuari][i];
                auxPosicio++;
            }
        }

        // Eliminar zeros sobrants
        uint[] memory auxFinalidAssociacions = new uint[](auxPosicio);
        uint[] memory auxDataAssociacoins = new uint[](auxPosicio);
        for (uint i = 0; i < auxPosicio; i++) {
            auxFinalidAssociacions[i] = auxIdAssociacions[i];
            auxDataAssociacoins[i] = associacionsMap[auxIdAssociacions[i]].dataFi;
        }

        return (auxFinalidAssociacions, auxDataAssociacoins);
    }


    function sensorAssociacio(uint _idAssoaciacio) public view onlyByContractes(msg.sender) returns(address aSensor){
        return associacionsMap[_idAssoaciacio].aSensor;
    }



    ///// GESTIÓ MEDICAMENT /////

    function regitraMedicament(uint _ium, string memory _nom, int16 _minTemp, int16 _maxTemp, uint16 _numMaxRegistres) public onlyByContractes(msg.sender){
        require(medicamentsMap[_ium].numMaxRegistres == 0, "El medicament ja existeix");
        require(_numMaxRegistres > 0, "Nombre maxim de registres ha de ser major que 0");
        require(bytes(_nom).length > 2, "Llargaria minima del nom");
    

        Medicament memory m;
        m.nom = _nom;
        m.minTemp = _minTemp;
        m.maxTemp = _maxTemp;
        m.numMaxRegistres = _numMaxRegistres;
        medicamentsMap[_ium] = m;
    }

    function visualitzaMedicament(uint _ium) public view onlyByContractes(msg.sender) returns(uint ium, string memory nom, int16 minTemp, int16 maxTemp, uint16 numMaxRegistres) {
        return (_ium, medicamentsMap[_ium].nom, medicamentsMap[_ium].minTemp, medicamentsMap[_ium].maxTemp, medicamentsMap[_ium].numMaxRegistres);
    }
    
}