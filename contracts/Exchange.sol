//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public cryptoDevTokenAddress;

    constructor(address _cryptoDevTokenAddress)
        ERC20("CryptoDev LP Token", "CDLP")
    {
        require(_cryptoDevTokenAddress != address(0), "not a valid address");
        cryptoDevTokenAddress = _cryptoDevTokenAddress;
    }

    /**
    @dev Returns the amount of `Crypto Dev Tokens` held by the contract
    @return amount of crypto dev tokens in this contract, i.e, the crypto dev token reserve
     */

    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    /**
     @dev Adds liquidity to the exchange.
     @return uint256 the amount of liquidity tokens minted
      */

    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();

        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        /*
        If the reserve is empty, intake any user supplied value for
        `Ether` and `Crypto Dev` tokens because there is no ratio currently
    */
        if (cryptoDevTokenReserve == 0) {
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethBalance - msg.value;
            uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
                (ethReserve);
            require(
                _amount >= cryptoDevTokenAmount,
                "less then minimum amount required to maintain ratio"
            );
            ERC20.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);

            liquidity = (msg.value * totalSupply()) / (ethReserve);
            _mint(msg.sender, liquidity);
        }

        return liquidity;
    }

    /**
     * @dev Returns the amount Eth/Crypto Dev tokens that would be returned to the user
     * in the swap
     */

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 ethAmount = (ethReserve * _amount) / (_totalSupply);
        uint256 cryptoDevTokenAmount = (getReserve() * _amount) /
            (_totalSupply);

        _burn(msg.sender, _amount);
        (bool sent, ) = (msg.sender).call{value: ethAmount}("");
        require(sent, "failed to send eth");

        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
    }

    /**
     * @dev Returns the amount Eth/Crypto Dev tokens that would be returned to the user
     * in the swap
     */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 numerator = (outputReserve * inputAmount * 99);
        uint256 denominator = (inputReserve + inputAmount) * 100;

        return numerator / denominator;
    }

    /**
     * @dev Swaps Eth for CryptoDev Tokens
     */

    function ethToCryptoDevToken(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }

    /**
     * @dev Swaps CryptoDev Tokens for Eth
     */

    function cryptoDevTokenToEth(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        (bool sent, ) = msg.sender.call{value: ethBought}("");
        require(sent, "failed to send eth");
    }
}
