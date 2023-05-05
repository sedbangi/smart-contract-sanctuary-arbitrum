// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuestionData.sol";
import "./interfaces/IGameController.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Quiz is Ownable
{
    using SafeMath for uint256;

    IGameController public GameCotrollerContract;
    IQuestionData public QuestionDataContract;
    IERC20 public TokenReward;  // CyberCredit

    mapping(address => uint256) public TimeTheNextToDoQuest;
    mapping(address => uint256) public TimeTheNextSubmit;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;
    mapping(address => mapping(uint256 => uint256)) public ListResultAnswersUser;
    mapping(address => uint256) public BlockReturnDoQuestion; // suport client
    mapping(address => uint256) public BlockReturnSubmitQuestion; // suport client

    uint256 public DelayToDoQuest;  // block
    uint256 public TotalQuestionContract;
    uint256 public TotalQuestionOnDay;

    uint256 public BonusAnswerCorrect = 10e18;

    event OnDoQuestOnDay(address user, uint256 blockNumber);
    event OnResultQuestion(uint256 totalAnswerCorrect, uint256 totalBonus);

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

    constructor(IQuestionData questionDataContract, IERC20 tokenReward) 
    {
        QuestionDataContract = questionDataContract;
        TokenReward = tokenReward;

        // config
        DelayToDoQuest = 7168;
        TotalQuestionContract =  20;
        TotalQuestionOnDay = 3;
        BonusAnswerCorrect = 5461e18;
    }

    modifier isHeroNFTJoinGame()
    {
        address user = _msgSender();
        require(GameCotrollerContract.HeroNFTJoinGameOfUser(user) != 0, "Error: Invaid HeroNFT join game");
        _;
    }

    function SetGameCotrollerContract(IGameController gameCotrollerContract) public onlyOwner 
    {
        GameCotrollerContract = gameCotrollerContract;
    }

    function SetQuestionDataContract(IQuestionData newQuestionDataContract) public onlyOwner
    {
        QuestionDataContract = newQuestionDataContract;
    }

    function SetTokenReward(IERC20 newTokenReward) public onlyOwner
    {
        TokenReward = newTokenReward;
    }

    function SetDelayToDoQuest(uint256 newDelayToDoQuest) public onlyOwner
    {
        DelayToDoQuest = newDelayToDoQuest;
    }

    function SetTotalQuestionContract(uint256 newTotalQuestionContract) public onlyOwner
    {
        TotalQuestionContract = newTotalQuestionContract;
    }
    
    function SetTotalQuestionOnDay(uint256 newTotalQuestionOnDay) public onlyOwner
    {
        TotalQuestionOnDay = newTotalQuestionOnDay;
    }

    function SetBonusAnswerCorrect(uint256 newBonusAnswerCorrect) public onlyOwner
    {
        BonusAnswerCorrect = newBonusAnswerCorrect;
    }
    function DoQuestOnDay() public isHeroNFTJoinGame
    {
        address user = msg.sender;
        require(block.number > TimeTheNextToDoQuest[user], "Error To Do Quest: It's not time to ask quest");

        for(uint256 oldResultAnswer = 0; oldResultAnswer < TotalQuestionOnDay; oldResultAnswer++)
        {
            delete ListResultAnswersUser[user][oldResultAnswer];
        }

        uint256 from1 = 0;
        uint256 to1 = TotalQuestionContract.div(TotalQuestionOnDay).sub(1);

        uint256 from2 = to1.add(1);
        uint256 to2 = from2.add(TotalQuestionContract.div(TotalQuestionOnDay).sub(1));

        uint256 from3 = to2.add(1);
        uint256 to3 = TotalQuestionContract.sub(1);

        ListQuestionsUser[user][0] = RandomNumber(0, user, from1, to1);
        ListQuestionsUser[user][1] = RandomNumber(1, user, from2, to2);
        ListQuestionsUser[user][2] = RandomNumber(2, user, from3, to3);

        TimeTheNextToDoQuest[user] = block.number.add(DelayToDoQuest);
        BlockReturnDoQuestion[user] = block.number;

        emit OnDoQuestOnDay(user, BlockReturnDoQuestion[user]);
    }

    function GetDataQuest(address user) public view returns(
        Question[] memory data,
        uint256 timeTheNextToDoQuest,
        uint256 timeTheNextSubmit,
        uint256 delayToDoQuest,
        uint256 blockReturnDoQuestion
        )
    {
        data = new Question[](TotalQuestionOnDay);

        if(TimeTheNextToDoQuest[user] > block.number)
        {
            for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
            {
                uint256 questionNumber = ListQuestionsUser[user][indexQuestion];

                (data[indexQuestion].Question,
                data[indexQuestion].Answer0,
                data[indexQuestion].Answer1,
                data[indexQuestion].Answer2,
                data[indexQuestion].Answer3, ) = QuestionDataContract.ListQuestionsContract(questionNumber);
            }
        }
        else 
        {
            for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
            {
                data[indexQuestion].Question = "";
                data[indexQuestion].Answer0 = "";
                data[indexQuestion].Answer1 = "";
                data[indexQuestion].Answer2 = "";
                data[indexQuestion].Answer3 = "";
            }
        }

        timeTheNextToDoQuest = (TimeTheNextToDoQuest[user] < block.number) ? 0 : TimeTheNextToDoQuest[user].sub(block.number);
        timeTheNextSubmit = TimeTheNextSubmit[user];
        delayToDoQuest = DelayToDoQuest;
        blockReturnDoQuestion = BlockReturnDoQuestion[user];
    }

    function SubmitQuestions(uint256[] calldata results) public
    {
        address user = msg.sender;
        require(block.number > TimeTheNextSubmit[user], "Error Submit Question: It's not time to submit yet");
        require(block.number <= TimeTheNextToDoQuest[user], "Error Submit Question: submission timeout");

        uint256 totalAnswerCorrect = 0;
        // for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        // {
        //     uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
        //     (,,,,,uint256 resultAnswerQuestionInContract) = QuestionDataContract.ListQuestionsContract(questionNumber);
        //     uint256 resultAnswerQuestionOfUser = results[indexQuestion];

        //     if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
        //     {
        //         ListResultAnswersUser[user][indexQuestion] = 1; // 1: true, 0: false;
        //         totalAnswerCorrect = totalAnswerCorrect.add(1);
        //     }
        //     delete ListQuestionsUser[user][indexQuestion];
        // }

        (uint256 answer0, uint256 answer1, uint256 answer2) = QuestionDataContract.ListAnswerQuestions(
            ListQuestionsUser[user][0], ListQuestionsUser[user][1], ListQuestionsUser[user][2]
        );

        if(answer0 == results[0])
        {
            ListResultAnswersUser[user][0] = 1; // 1: true, 0: false;
            totalAnswerCorrect = totalAnswerCorrect.add(1);
        }

        if(answer1 == results[1])
        {
            ListResultAnswersUser[user][1] = 1; // 1: true, 0: false;
            totalAnswerCorrect = totalAnswerCorrect.add(1);
        }

        if(answer2 == results[2])
        {
            ListResultAnswersUser[user][2] = 1; // 1: true, 0: false;
            totalAnswerCorrect = totalAnswerCorrect.add(1);
        }

        // if(totalAnswerCorrect > 0) DoBonusToken(user, totalAnswerCorrect);

        TokenReward.transfer(user, totalAnswerCorrect.mul(BonusAnswerCorrect));

        TimeTheNextSubmit[user] = TimeTheNextToDoQuest[user];
        BlockReturnSubmitQuestion[user] = block.number;

        emit OnResultQuestion(totalAnswerCorrect, totalAnswerCorrect.mul(BonusAnswerCorrect));
    }

    function DoBonusToken(address user, uint256 totalAnswerCorrect) private 
    {
        if(TokenReward.balanceOf(address(this)) >= totalAnswerCorrect.mul(BonusAnswerCorrect))
        {
            TokenReward.transfer(user, totalAnswerCorrect.mul(BonusAnswerCorrect));
        }
        else
        {
            TokenReward.transfer(user, TokenReward.balanceOf(address(this)));
        }
    }  

    function GetResultAnswers(address user) public view returns(
        uint256[] memory data,
        uint256 totalBonusToken,
        uint256 blockReturnSubmitQuestion
    )
    {
        data =  new uint256[](TotalQuestionOnDay);
        totalBonusToken = 0;

        for(uint256 resultAnswers = 0; resultAnswers < TotalQuestionOnDay; resultAnswers++)
        {
            data[resultAnswers] = ListResultAnswersUser[user][resultAnswers];
            if(ListResultAnswersUser[user][resultAnswers] == 1)
            {
                totalBonusToken = totalBonusToken.add(BonusAnswerCorrect);
            }
        }
        blockReturnSubmitQuestion = BlockReturnSubmitQuestion[user];
    }

    function RandomNumber(uint256 count, address user, uint256 from, uint256 to) public view returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit)));
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count, seed, user)));
        return randomHash % (to - from + 1) + from;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuestionData
{
    function ListQuestionsContract(uint256 indexQuest) external pure returns(
        string memory question,
        string memory answer0,
        string memory answer1,
        string memory answer2,
        string memory answer3,
        uint256 answerResult
    );

    function ListAnswerQuestions(uint256 indexQuestion0, uint256 indexQuestion1, uint256 indexQuestion2) external view 
    returns (uint256 answer0, uint256 answer1, uint256 answer2); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameController
{
    function HeroNFTJoinGameOfUser(address user) external view returns(uint256);
    
    function RobotNFTJoinGameOfUser(address user) external pure returns (
        uint256 BlockJoin, // the block at which the NFT robot was added to the game
        uint256 RobotId // the ID of the NFT robot
    );


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}