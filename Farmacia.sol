// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import './Processador.sol';
import './Autoritat.sol';

// Contracte dels farmacèutics
contract Farmacia {

    // --------------------------------------------------------- DECLACACIONS INICIALS ---------------------------------------------------------
    
    Autoritat private autor;
    Processador private process;

    address private aUsuaris;
    address private aProcessador;
    address private aFarmacia;

    enum estatActor {baixa, alta}


    // Constructor del contracte
    constructor (address _aProcessador, address _aAutoritat) {
        process = Processador(_aProcessador);
        aProcessador = _aProcessador;
        autor = Autoritat(_aAutoritat);
        aFarmacia = address(uint160(address(this)));
    }

    // Estructura d'usuaris
    struct Usuari {
        estatActor estat;
    }


    // Mapping per obtenir les dades d'un usuari amb la seva adreça
    mapping(address => Usuari) private UsuarisMap;


    // --------------------------------------------------------- MODIFIERS ---------------------------------------------------------

    // Només pels farmacèutics registrats
    modifier onlyByFarmecautics(address _account) {
        require(
            autor.farmaceuticValid(_account),
            "Nomes farmaceutics registrats"
        );
        _;
    }

    // Només l'adreça dels contractes desplegats
    modifier onlyByContractes(address _account) {
        require(
            (_account == aUsuaris) || (_account == aProcessador) || (_account == aFarmacia),
            "Nomes el contractes"
        );
        _;
    }



    // --------------------------------------------------------- FUNCTIONS ---------------------------------------------------------

    ///// GESTIÓ USUARIS /////

    function registraUsuari(address _aUsuari) public onlyByFarmecautics(msg.sender){
        Usuari memory u;
        u.estat = estatActor.alta;
        UsuarisMap[_aUsuari] = u;
    }


    function baixaUsuari(address _aUsuari) public onlyByFarmecautics(msg.sender){
        require(UsuarisMap[_aUsuari].estat == estatActor.alta, "Usuari ja te estat \"baixa\"");
        UsuarisMap[_aUsuari].estat = estatActor.baixa;
    }


    function usuariValid(address _account) public view onlyByContractes(msg.sender) returns(bool usuariEsValid){
        if (UsuarisMap[_account].estat == estatActor.alta) {
            return true;
        } else {
            return false;
        }
    }



    ///// GESTIÓ MEDICAMENTS /////

    function registraMedicament(uint _ium, string memory _nom, int16 _minTemp, int16 _maxTemp, uint16 _numMaxRegistres) public onlyByFarmecautics(msg.sender){
       process.regitraMedicament(_ium, _nom, _minTemp, _maxTemp, _numMaxRegistres);
    }

    function visualitzaMedicament(uint _ium) public view onlyByFarmecautics(msg.sender) returns(uint ium, string memory nom, int16 minTemp, int16 maxTemp, uint16 numMaxRegistres) {
        return process.visualitzaMedicament(_ium);
    }



    ///// GESTIÓ ASSOCIACIONS /////

    function registraAssociacio(address _aUsuari, address _aSensor, uint _ium, uint _dataFi) public onlyByFarmecautics(msg.sender) returns(uint idAssociacio){
        require(UsuarisMap[_aUsuari].estat == estatActor.alta, "Usuari no registrat");
        return process.registraAssociacio(_aUsuari, _aSensor, _ium, _dataFi);
    }


    function baixaAssociacio(uint _idAssociacio) public onlyByFarmecautics(msg.sender){
        process.baixaAssociacio(_idAssociacio);
    }


    function visualitzaAssociacionsUsuari(address _aUsuari) public view onlyByFarmecautics(msg.sender) returns(uint[] memory idAssociacions, uint[] memory dataAssociacions){
        return process.visualitzaAssociacionsUsuari(_aUsuari);
    }



    ///// REBRE ADREÇES D'ALTRES SC //////

    function rebreAddressContractes(address _aUsuaris) public onlyByContractes(msg.sender) {
        aUsuaris = _aUsuaris;
    }
    
}