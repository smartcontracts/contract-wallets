pragma solidity ^0.5.0;

/**
 * @author Kelvin Fichter (@kelvinfichter)
 * @notice Simple wallet that supports ETH transfers with confirmations. Owner
 * of the wallet needs to submit one transaction to start the transfer and a
 * second transaction to either confirm it or cancel it.
 *
 * This is a proof of concept contract and it's missing a lot of critical
 * features. Ideally you'd want some sort of central registry contract where
 * wallets can watch for events, but I'm lazy and here to make a point.
 */
contract ConfirmationWallet {
    /*
     * Structs
     */

    struct Transfer {
        address payable recipient;
        uint256 amount;
        bool cancelled;
        bool confirmed;
    }


    /*
     * Internal Variables
     */

    address owner;
    uint256 allocated;
    uint256 nonce;
    mapping (uint256 => Transfer) transfers;


    /*
     * Events
     */

    event TransferStarted(
        address indexed _recipient,
        uint256 indexed _nonce,
        uint256 _amount
    );

    event TransferCancelled(
        uint256 indexed _nonce
    );

    event TransferConfirmed(
        uint256 indexed _nonce
    );


    /*
     * Modifiers
     */

    /**
     * @notice Only allows the owner of the wallet to call a tagged function.
     */
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the owner of this wallet can call this function."
        );

        _;
    }

    /**
     * @notice Only allows calls that use a valid transaction nonce.
     * @param _nonce Transaction nonce to verify.
     */
    modifier onlyValidNonce(uint256 _nonce) {
        require(
            _nonce < nonce,
            "Transfer with the given nonce does not exist."
        );

        Transfer storage transfer = transfers[_nonce];
        
        require(
            !transfer.confirmed,
            "Transfer has already been confirmed."
        );
        require(
            !transfer.cancelled,
            "Transfer has already been cancelled."
        );

        _;
    }


    /*
     * Public Functions
     */

    /**
     * @notice Fallback. Allows anyone to send ETH to the contract.
     */
    function () external payable { }

    /**
     * @notice Constructor. Sets the contract creator as the owner.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Starts an ETH transfer to a recipient address.
     * @param _recipient Address to send to.
     * @param _amount Amount to send in wei.
     * @return ID of the transfer.
     */
    function send(
        address payable _recipient,
        uint256 _amount
    ) public onlyOwner {
        require(
            allocated + _amount <= address(this).balance,
            "Cannot allocate more than available balance."
        );
        
        transfers[nonce] = Transfer({
            recipient: _recipient,
            amount: _amount,
            confirmed: false,
            cancelled: false
        });

        emit TransferStarted(_recipient, nonce, _amount);

        nonce += 1;
        allocated += _amount;
    }

    /**
     * @notice Confirms a transfer.
     * @param _nonce Nonce of the transfer to confirm.
     */
    function confirm(uint256 _nonce) public onlyOwner onlyValidNonce(_nonce) {
        Transfer storage transfer = transfers[_nonce];
        transfer.confirmed = true;

        transfer.recipient.transfer(transfer.amount);
        allocated -= transfer.amount;

        emit TransferConfirmed(_nonce);
    }

    /**
     * @notice Cancels a transfer.
     * @param _nonce Nonce of the transfer to cancel.
     */
    function cancel(uint256 _nonce) public onlyOwner onlyValidNonce(_nonce) {
        Transfer storage transfer = transfers[_nonce];
        transfer.cancelled = true;
        
        allocated -= transfer.amount;

        emit TransferCancelled(_nonce);
    }
}
