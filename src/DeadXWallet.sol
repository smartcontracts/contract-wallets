pragma solidity ^0.5.0;

/**
 * @author Kelvin Fichter (@kelvinfichter)
 * @notice Simple dead x's switch ETH wallet. Normally acts as a simple wallet
 * that can send and receive ETH. However, the owner specifies a list of
 * beneficiaries who can attempt to recover funds from the contract if
 * something happens to the owner. Recovery attempts can only be made by
 * staking a "recovery bond". Owner can cancel recovery attempts within some
 * pre-defined timeout window and collect the recovery bond. Otherwise, the
 * beneficiary can finalize the recovery and collect the contract's balance.
 *
 * This contract is a proof of concept and shouldn't really be used as-is.
 * Several variables (timeout, bond) are left as constants but could be
 * user-defined instead. Could also modify the contract to allow users to
 * change the set of beneficiaries.
 */
contract DeadXWallet {
    /*
     * Structs
     */
     
    struct Recovery {
        address payable beneficiary;
        uint256 timeout;
    }
    
    
    /*
     * Public Variables
     */
    
    uint256 constant RECOVERY_TIMEOUT = 172800;
    uint256 constant RECOVERY_BOND = 1 ether;


    /*
     * Internal Variables
     */
    
    address owner;
    mapping (address => bool) beneficiaries;
    Recovery recovery;


    /*
     * Events
     */

    event Transfer(
        address indexed _recipient,
        uint256 _amount
    );
    
    event RecoveryStarted(
        address indexed _beneficiary,
        uint256 _timeout
    );

    event RecoveryCancelled(
        string _message
    );
    
    event RecoveryFinalized(
        address indexed _beneficiary
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


    /*
     * Public Methods
     */

    /**
     * @notice Fallback. Allows anyone to send ETH to the contract.
     */
    function () external payable { }

    /**
     * @notice Constructor. Sets the contract creator as the owner.
     */
    constructor(address[] memory _beneficiaries) public {
        owner = msg.sender;
        
        for (uint i = 0; i < _beneficiaries.length; i++) {
            beneficiaries[_beneficiaries[i]] = true;
        }
    }

    /**
     * @notice Sends an amount of ETH to a recipient address.
     * @param _recipient Address to send funds to.
     * @param _amount Amount to send in wei.
     */
    function send(
        address payable _recipient,
        uint256 _amount
    ) public onlyOwner {
        _recipient.transfer(_amount);
        emit Transfer(_recipient, _amount);
    }

    /**
     * @notice Allows a beneficiary to start the recovery process. Requires
     * that the beneficiary place a bond, which they'll lose if the owner
     * cancels the recovery attempt.
     */
    function recover() public payable {
        require(
            beneficiaries[msg.sender],
            "Sender is not a beneficiary."
        );
        
        require(
            msg.value == RECOVERY_BOND,
            "Insufficient recovery bond."
        );

        require(
            recovery.beneficiary == address(0),
            "Recovery has already been started."
        );
        
        recovery.beneficiary = msg.sender;
        recovery.timeout = block.number + RECOVERY_TIMEOUT;
        
        emit RecoveryStarted(recovery.beneficiary, recovery.timeout);
    }
    
    /**
     * @notice Allows the owner of the wallet to cancel a recovery attempt.
     * Owner receives the beneficiary's bond for their trouble.
     */
    function cancel() public onlyOwner {
        require(
            recovery.beneficiary != address(0),
            "Recovery attempt is not active."
        );
        
        recovery.beneficiary = address(0);
        recovery.timeout = 0;
        
        emit RecoveryCancelled("Stop trying to steal my crypto, mom.");
    }
    
    /**
     * @notice Allows the recovering beneficiary to finalize a recovery attempt
     * after the timeout has elapsed.
     */
    function finalize() public {
        require(
            recovery.beneficiary != address(0),
            "Recovery attempt is not active."
        );

        require(
            msg.sender == recovery.beneficiary,
            "Sender is not recovering beneficiary."
        );
        
        require(
            block.number > recovery.timeout,
            "Recovery timeout has not elapsed."
        );
        
        recovery.beneficiary = address(0);
        recovery.timeout = 0;
        
        msg.sender.transfer(address(this).balance);
        
        emit RecoveryFinalized(msg.sender);
    }
}
