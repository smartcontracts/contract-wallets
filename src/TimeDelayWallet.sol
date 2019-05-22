pragma solidity ^0.5.0;

/**
 * @author Kelvin Fichter (@kelvinfichter)
 * @notice Simple wallet that supports ETH transfers with a delay. Very similar
 * to the ConfirmationWallet construction, but makes some minor tweaks. Sender
 * can start a transfer by specifying an amount and a recipient. Sender can
 * then confirm or cancel the transfer within a timeout window. After the
 * timeout window has elapsed, the recipient can confirm the spend on the
 * sender's behalf.
 *
 * As stated elsewhere in this repo, this contract is mainly a proof of concept
 * and isn't intended to be used as-is. You'd likely want to add some
 * enhancements to make the contract practical for real-world usage.
 */
contract TimeDelayWallet {
    /*
     * Structs
     */

    struct Transfer {
        address payable recipient;
        uint256 amount;
        bool cancelled;
        bool confirmed;
        uint256 timeout;
    }


    /*
     * Constants
     */

    uint256 constant TRANSFER_TIMEOUT = 5760;


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
        uint256 _amount,
        uint256 _timeout
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
        
        uint256 timeout = block.number + TRANSFER_TIMEOUT;
        transfers[nonce] = Transfer({
            recipient: _recipient,
            amount: _amount,
            confirmed: false,
            cancelled: false,
            timeout: timeout
        });

        emit TransferStarted(_recipient, nonce, _amount, timeout);

        nonce += 1;
        allocated += _amount;
    }

    /**
     * @notice Confirms a transfer.
     * @param _nonce Nonce of the transfer to confirm.
     */
    function confirm(uint256 _nonce) public onlyValidNonce(_nonce) {
        Transfer storage transfer = transfers[_nonce];

        require(
            msg.sender == owner
            || block.number > transfer.timeout,
            "Sender is not owner or transfer timeout has not elapsed."
        );

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
