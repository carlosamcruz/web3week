// SPDX-License-Identifier: MIT


/*
    Exercicios:

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
    bool open;
}

contract FloodHelp {

    uint public lastId = 0;
    mapping(uint => Request) public requests;

    function openRequest(string memory title, string memory description, string memory contact, uint goal) public {
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
            open: true
        });
    }

    function closeRequest(uint id) public {
        address author = requests[id].author;
        uint balance = requests[id].balance;
        uint goal = requests[id].goal;
        require(requests[id].open && (msg.sender == author || balance >= goal), unicode"Você não pode fechar este pedido");

        requests[id].open = false;

        if(balance > 0){
            requests[id].balance = 0;
            payable(author).transfer(balance);
        }
    }

    function donate(uint id) public payable {
        requests[id].balance += msg.value;
        if(requests[id].balance >= requests[id].goal)
            closeRequest(id);
    }

    function getOpenRequests(uint startId, uint quantity) public view returns (Request[] memory){
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