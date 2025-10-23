// SPDX-License-Identifier: MIT

/*
https://solidity-by-example.org/app/multi-sig-wallet

Let's create an multi-sig wallet. Here are the specifications.

The wallet owners can:
  submit a transaction
  approve and revoke approval of pending transcations
  anyone can execute a transcation after enough owners has approved it.
*/

pragma solidity ^0.8.0;


// multi signature wallet contract
contract MultiSigWallet {

    // deposit event
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    // submit transaction event
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners; // list of owners
    mapping(address => bool) public isOwner; // mapping to check if an address is an owner
    uint256 public numConfirmationRequired; // number of confirmations required

    // transaction structure
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed; // mapping to check if a transaction is confirmed by an owner

    Transaction[] public transactions; // list of transactions

    // modifier to check if the caller is an owner
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    // modifier to check if the transaction exists
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
    // modifier to check if the transaction is not executed
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    // modifier to check if the transaction is not confirmed by the caller
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    // contract constructor
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required"); // at least one owner
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        ); // valid number of confirmations

        // loop through the owners array
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i]; // get the owner address

            require(owner != address(0), "invalid owner"); // owner address cannot be zero
            require(!isOwner[owner], "owner not unique"); // owner address must be unique

            isOwner[owner] = true; // mark the address as an owner
            owners.push(owner); // add the owner to the owners array
        }

        numConfirmationRequired = _numConfirmationsRequired; // set the number of confirmations required
    }

    // function to receive ether
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    // function to submit a transaction
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, numConfirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationRequired, "cannot execute tx");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getfOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}