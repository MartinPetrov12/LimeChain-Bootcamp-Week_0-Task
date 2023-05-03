// SPDX-License-Identifier: Unlicense
pragma solidity >= 0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

struct Book {
    uint bookId;
    uint copies;
    address[] usersHavingIt;
    string name;
}

struct BookAndId {
    uint bookId;
    string name;
}
contract Library is Ownable {

    uint bookIdNonce;
    address[] allTimeHistory;
    mapping(address => uint[]) userToBooks;
    Book[] books;
    
    /**
        Initializes the contract. Sets the bookIdNonce to 0
    */
    constructor() {
        bookIdNonce = 0;
    }

    /**
        The function allows the owner of the contract to add books
        to the library. The amount of copies has to be a positive number.
        BookIdNonce is an identifier, which is unique for each book.
    */
    function addBooks(string memory _name, uint _bookCopies) public onlyOwner {
        require(_bookCopies > 0, "The amount of books to be added should be positive");
        address[] memory newAddresses;
        books.push(Book(bookIdNonce, _bookCopies, newAddresses, _name));
        bookIdNonce += 1;
    }

    /**
        The function returns the books available for borrow.
        It does that by looping through the array of books and 
        checking which books have more copies than the amount of users
        who have currently borrowed the book. 
        The return object consists of the id an name of the book.
    */
    function getAvailableBooks() public view returns(BookAndId[] memory) {
        BookAndId[] memory result = new BookAndId[](books.length);
        for(uint i=0; i<books.length; i++) {
            if(books[i].copies > books[i].usersHavingIt.length) {
                result[i] = BookAndId(books[i].bookId, books[i].name);
            }
        }
        
        return result;
    }

    /**
        The function reserves the book if the following conditiosn are met:
            - a book with such id exists
            - if there are available copies
            - if the user requesting it does not have a copy of it 

        If a book is reserved:
            - the user is pushed in 'usersHavingIt' list of the book
            - the id of the book is saved in the mapping 'userToBooks'
            - if it's the first time a book is reserved from the 
            address of the message sender, it is pushed in 'allTimeHistory'
        
    */
    function reserveBook(uint _desiredBookId) public {
        bool _bookFound = false;
        for(uint i = 0; i < books.length; i++) {
            if(books[i].bookId == _desiredBookId) {
                _bookFound = true;
                break;
            }
        }
        require(_bookFound, "There is no such book"); 

        Book storage _desiredBook = books[_desiredBookId];
        require(_desiredBook.copies > _desiredBook.usersHavingIt.length, "All copies are taken");

        uint[] storage _takenBooks = userToBooks[msg.sender];
        for(uint i = 0; i < _takenBooks.length; i++) {
            if(_takenBooks[i] == _desiredBookId) {
                revert("The user already has a copy of the book");
            }
        }
        _desiredBook.usersHavingIt.push(msg.sender);
        _takenBooks.push(_desiredBookId);

        bool _firstTimeUser = false;

        for(uint i = 0; i < allTimeHistory.length; i++) {
            if(allTimeHistory[i] == msg.sender) {
                _firstTimeUser = true;
                break;
            }
        }
        if(_firstTimeUser == false) {
            allTimeHistory.push(msg.sender);
        }
    }

    /**
       The function allows the user to return a book.
       First, it is checked whether has reserved any books at all.
       That is needed since a memory array is created and it's size
       can not be less than 0. 
       Then, it is checked if a book with such id exists and whether
       the user currently has it. If both conditions are met, 
       the book is removed from the mapping 'userToBooks" and 
       'usersHavingIt' is updated for the book.
    */
    function returnBook(uint _bookId) public {
        uint[] storage _takenBooks = userToBooks[msg.sender];
        require(_takenBooks.length > 0, "User has no books to return");

        bool doesBookExist = false;
        uint[] memory _newTakenBooks = new uint[](_takenBooks.length-1);
        uint counter = 0;
        for(uint i = 0; i < _takenBooks.length; i++) {
            if(_takenBooks[i] == _bookId) {
                doesBookExist = true;
            } else {
                _newTakenBooks[counter] = (_takenBooks[i]);
                counter = counter + 1;
            }
        }
        require(doesBookExist == true, "User has not reserved book with such id");

        userToBooks[msg.sender] = _newTakenBooks;
        bool bookFound = false;
        for(uint i = 0; i < books.length; i++) {
            if(books[i].bookId == _bookId) {
                bookFound = true;
                break;
            }
        }
        require(bookFound, "There is no such book"); 
        
        Book storage returnedBook = books[_bookId];
        address[] memory newUsersHavingIt = new address[](returnedBook.usersHavingIt.length - 1);
        // reuse the previously defined counter
        counter = 0;

        for(uint i = 0; i < returnedBook.usersHavingIt.length; i++) {
            if(returnedBook.usersHavingIt[i] != msg.sender) {
                newUsersHavingIt[counter] = returnedBook.usersHavingIt[i];
                counter++;
            }
        }
        returnedBook.usersHavingIt = newUsersHavingIt;
    }

    function _getBooks() view external returns(Book[] memory) {
        return books;
    }

    function _getAllTimeBorrowers() view external returns(address[] memory) {
        return allTimeHistory;
    }

}