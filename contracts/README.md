# StarkPay Smart Contract

A minimal payment system smart contract deployed on Starknet, demonstrating core StarkPay functionality for the hackathon submission.

## Contract Features

- **User Registration**: Register users with unique usernames
- **Payment System**: Send payments between registered users
- **Balance Management**: Track user balances and payment history
- **Statistics**: Monitor sent/received amounts and transaction counts
- **Event Logging**: Emit events for user registration and payments

## Contract Structure

### Core Functions

```cairo
// User management
fn register_user(username: felt252)
fn is_registered(user: ContractAddress) -> bool
fn get_username(user: ContractAddress) -> felt252

// Payment functions
fn send_payment(recipient: ContractAddress, amount: u256, message: felt252)
fn get_balance(user: ContractAddress) -> u256

// Statistics
fn get_total_sent(user: ContractAddress) -> u256
fn get_total_received(user: ContractAddress) -> u256
fn get_payment_count(user: ContractAddress) -> u32

// Contract info
fn get_version() -> felt252
```

### Storage Structure

- **usernames**: Maps addresses to usernames
- **balances**: User token balances (internal tokens for demo)
- **total_sent**: Total amount sent per user
- **total_received**: Total amount received per user
- **payment_count**: Number of payments made per user

## Deployment

### Prerequisites

1. **Scarb** (Cairo package manager): Version 2.11.4+
2. **Starkli** (Starknet CLI): Version 0.4.2+
3. **Starknet Account** (for testnet deployment)

### Quick Deployment

```bash
cd contracts/starkpay_contract
./deploy.sh
```

### Manual Deployment

1. **Build the contract:**
   ```bash
   scarb build
   ```

2. **Declare the contract:**
   ```bash
   starkli declare target/dev/starkpay_contract.contract_class.json --network sepolia
   ```

3. **Deploy the contract:**
   ```bash
   starkli deploy <CLASS_HASH> <OWNER_ADDRESS> --network sepolia
   ```

## Contract Verification

After deployment, verify the contract on:
- **Starkscan**: https://sepolia.starkscan.co/contract/{CONTRACT_ADDRESS}
- **Voyager**: https://sepolia.voyager.online/contract/{CONTRACT_ADDRESS}

## Testing the Contract

### Register a user:
```bash
starkli invoke <CONTRACT_ADDRESS> register_user <USERNAME> --network sepolia
```

### Check user registration:
```bash
starkli call <CONTRACT_ADDRESS> is_registered <USER_ADDRESS> --network sepolia
```

### Send a payment:
```bash
starkli invoke <CONTRACT_ADDRESS> send_payment <RECIPIENT> <AMOUNT> <MESSAGE> --network sepolia
```

### Check balance:
```bash
starkli call <CONTRACT_ADDRESS> get_balance <USER_ADDRESS> --network sepolia
```

## Demo Features

For hackathon demonstration purposes:
- New users receive 1,000 demo tokens upon registration
- Contract owner receives 10,000 demo tokens at deployment
- All amounts are in Wei format (18 decimals)

## Security Considerations

This is a **minimal demo contract** for hackathon purposes. For production use, consider:

- Proper access controls
- Reentrancy protection  
- Integer overflow protection
- Gas optimization
- Professional security audit
- Integration with real tokens (ERC20)

## File Structure

```
contracts/
├── starkpay_contract/
│   ├── src/
│   │   └── lib.cairo          # Main contract code
│   ├── Scarb.toml             # Project configuration
│   ├── deploy.sh              # Deployment script
│   └── deployment_info.json   # Deployment results
└── README.md                  # This file
```

## Integration with iOS App

The deployed contract can be integrated with the StarkPay iOS app by:

1. **Update contract address** in `StarknetIntegration.swift`
2. **Use contract ABI** from build artifacts
3. **Configure network endpoint** for Sepolia testnet
4. **Implement contract calls** for user registration and payments

## Support

For questions about the contract deployment or integration:
- Check deployment logs in the console output
- Verify contract on Starknet block explorers
- Test contract functions with Starkli CLI

---

**Built for**: Starknet Hackathon - DEL-006 MVP Deployment  
**Team**: StarkPay - ITAM  
**Network**: Starknet Sepolia Testnet  
**Date**: October 2025