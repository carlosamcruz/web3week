// SPDX-License-Identifier: MIT

/*
    Exercicios Resolvidos:

    1 - validações na criação de request (campos e duplicidade de author se request aberta);
    2 - validação na doação para não doar 0;
    3 - validação no getOpenRequests (quantidade máxima);
    4 - admin do contrato pode fechar requests suspeitas;
    5 - mais algum campo na struct, ex.: total de doações;
    6 - request ter um status, aí quando cadastrada, fica pendente e admin tem de aprovar;
    7 - blacklists de carteiras (admin pode cadastrar carteiras bloqueadas);
    8 - não permitir doar para request muito antiga (fecha automaticamente por tempo);

*/

pragma solidity ^0.8.24;

struct Request {
    uint id;
    address author;
    string title;
    string description;
    string contact;
    uint timestamp;
    uint goal;
    uint balance;
    uint totaldoacoes;
    bool open;
    bool aproved;
    uint timeduration;
}

contract FloodHelpV2 {

    uint public lastId = 0;
    mapping(uint => Request) public requests;

    //Parte do Exercício 4: conta do administrador
    address public admin;

    //Parte do Execício 7: criação da lista negra 
    address[] public addblacklist;
    uint public nBlacklist = 0;

    constructor() {
        admin = msg.sender;
    }

    function openRequest(string memory title, string memory description, string memory contact, uint goal, uint timeduration) public {

        //Parte do Exercício 8: determinação de duração do contrato
        require(timeduration > 0 && goal > 0, unicode"informações inválidas");

        //Parte do Execício 7: não permite criação de request de endereços na lista negra 
        for(uint i = 0; i < addblacklist.length; i++)
        {
            require(msg.sender != addblacklist[i], unicode"endereço na lista negra" );
        }

        lastId++;
        requests[lastId] = Request({
            id: lastId,
            title: title,
            description: description,
            contact: contact,
            goal: goal,
            balance: 0,
            timestamp: block.timestamp,
            author: msg.sender,
            totaldoacoes: 0,
            open: true,
            aproved: false,
            timeduration: timeduration 
        });

        //Exercicio 1 - Verifica requisições repetidas:
        if(lastId > 1)
        {
            Request[] memory result = getOpenRequests(1, lastId - 1);

            for(uint i = 0; i < result.length; i ++)
            {
                    require(
                        result[i].author != msg.sender 
                        && keccak256(abi.encodePacked(result[i].title)) != keccak256(abi.encodePacked(title))
                        && keccak256(abi.encodePacked(result[i].description)) != keccak256(abi.encodePacked(description)),
                        unicode"Autor, ou Titulo, ou Descrição repetidos"
                    );
            } 
        }          
    }

    function closeRequest(uint id) public {
        address author = requests[id].author;
        uint balance = requests[id].balance;
        uint goal = requests[id].goal;

        require(requests[id].open && 
        (msg.sender == author || balance >= goal
        //Parte dos Exercícios 4 e 8: requests finalizadas pelo adim e por tempo
        || msg.sender == admin 
        || block.timestamp > (requests[id].timestamp + requests[id].timeduration)), 
        unicode"Você não pode fechar este pedido");

        requests[id].open = false;

        if(balance > 0){
            requests[id].balance = 0;
            payable(author).transfer(balance);
        }
    }

    function donate(uint id) public payable {
        //Parte do Execício 7: não permite doações de endereços na lista negra 
        for(uint i = 0; i < addblacklist.length; i++)
        {
            require(msg.sender != addblacklist[i], unicode"endereço na lista negra" );
        }

        //Parte do Execício 8: não permite doar para contrato muito antigo
        //finaliza o request automaticamente em caso de contratos antigos
        if(block.timestamp > (requests[id].timestamp + requests[id].timeduration))
            closeRequest(id);
        else 
        {
            //Execício 2: não pode doar 0
            require(msg.value != 0, unicode"não pode doar valor nulo");
            //Parte do Execício 6: Não pode doar para contrato não aprovado
            require(requests[id].aproved, unicode"contrato ainda não aprovado");
            requests[id].balance += msg.value;
            requests[id].totaldoacoes++;
            if(requests[id].balance >= requests[id].goal)
                closeRequest(id);
        }    
    }

    //Parte do Execício 6: Adim precisa aprovar o request
    function aprove(uint id) public {
        require(msg.sender == admin, unicode"somente o administrador pode aprovar o contrato");
        requests[id].aproved = true;
    }    

    //Parte do Execício 7: criação da lista negra
    //***Sou critico da lista negra de endereços, pois o usuário pode simplesmente usar outro endereço
    function newBlackList(address bladd) public {
        require(msg.sender == admin, unicode"somente o administrador pode inserir na blacklist");
        nBlacklist++;
        for(uint i = 0; i < addblacklist.length; i++)
        {
            require(bladd != addblacklist[i], unicode"endereço já está na blacklist" );
        }

        addblacklist.push(bladd);
        
        //Se houver request aberta em endereços na lista negra, finaliza automaticamente
        Request[] memory result = getOpenRequests(1, lastId);

        for(uint i = 0; i < result.length; i ++)
        {
            if(bladd == result[i].author)
            closeRequest(result[i].id);
        } 
          
    }    

    function getOpenRequests(uint startId, uint quantity) public view returns (Request[] memory){

        for(uint i = 0; i < addblacklist.length; i++)
        {
            require(msg.sender != addblacklist[i], unicode"endereço na lista negra" );
        }

        //Exercício 3: Não permite busca por quantidades maiores que o número de requests criadas
        if(quantity > lastId)
            quantity = lastId;

        Request[] memory result = new Request[](quantity);
        uint id = startId;
        uint count = 0;

        do {
            if(requests[id].open){
                result[count] = requests[id];
                count++;
            }

            id++;
        }
        while(count < quantity && id <= lastId);

        return result;
    }
}