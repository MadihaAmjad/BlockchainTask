// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract libraryManagement is ERC20{
    //State Variables
    address immutable  MasterLibrarin;
    address[] private librarians;
    uint256 bookId=1;
    uint MembersId =1;
    uint256 public bookCount;
    uint256 public memberIdCounter;
    uint private MaxBookLimit = 5;
    uint private MaxTimeLimit = 1 minutes;
    uint private Fine = 5; 
     
    constructor() ERC20("MagnusToken","MT"){
      MasterLibrarin = msg.sender;
    }
    //Modifiers
  modifier onlyMasterLibrarin(){
        require(msg.sender==MasterLibrarin,"only MasterLibrarin can call this function");
        _;
    }
    
    modifier onlyLibraryStaff(){
        require(! librarianExists[msg.sender],"only library staff can call this function");
        _;
    }
    modifier OnlyLibraryAdminStaff(){
        require(msg.sender==MasterLibrarin ||  librarianExists[msg.sender],"only MasterLibrarin and staff can perform this function    ");
        _;
    }
    modifier OnlyReservation(){
        require(msg.sender==MasterLibrarin ||  librarianExists[msg.sender] || members[msg.sender] ,"only MasterLibrarin,staff and library Mmebers can perform this function    ");
        _;
    }
      modifier onlyMember() {
        require(members[msg.sender], "Sender is not a member of the library management system");
        _;
    }
                     //ENUM
      enum Status{Available,Borrowed,Returned,Reserved,NotAvailable}

                     //EVENTS
      event AddBook(uint indexed  id,bytes indexed  _author,bytes indexed category,uint  publicationDate,uint  rackno,uint copiesavailable);
      event UpdateBook(uint indexed id,bytes indexed _author,bytes indexed category,uint publicationDate,uint rackno,uint copiesavailable);
      event DeleteBook(uint indexed id);
      event AddMembers(uint indexed  id, bytes indexed name, address indexed ofmember);
      event IssueBook(uint indexed BookId,uint indexed MembersId, address OfissuedBook);  
      event ReturnBooks(uint indexed BookId,uint indexed MembersId,address Ofmember);             
      event FinePaid(address indexed member, uint256 amount);
      event memberdeleted(uint indexed id,address indexed  member);
      event Updatemember(uint indexed memberid, bytes indexed   _newmemberName);
      event ReserveBooks(uint _BookId, uint _memberId);

    struct Books{
        uint Booksid;
        bytes bookTitle;
        bytes bookAuthor;
        bytes bookCategory;
        uint256 bookPublicationDate;
        uint256 bookRackNumber;
        uint256 bookCopiesAvailable;
        uint256 bookDueDate;
        address bookReservedBy;
        Status bookStatus;
        bool hasexist;
        uint Borrowed;
        address[] allBorrowers;
    }
    //Struct For Members
    struct Members{
       
        bytes memberName;
        address[] allmembers;
        uint256[] booksCheckedOut;
        uint256[] reservedBooks;
        bool registration;
        bool Memberhasexsit;
        address memberaddress;
         uint numBooksBorrowed;
        mapping(uint256 => address) addressById;
       mapping(uint=>mapping(address=>bool)) memberremove;
    }
                 //MAPPING
    mapping(uint256 => Books) public  books;
    mapping(bytes=> Books) private checkbook;
    mapping(uint => Members) private membersaddress;
    mapping (uint=>mapping(address=>Members)) private memberexsit;
    mapping(address =>bool) private members;
    mapping(uint256 => mapping(address => mapping(uint256 => Status))) private Bookstatus;
    mapping(address => bool) public librarianExists;

   // Function to ADD Librarian
    function addLibrarian(address _newLibrarian) public onlyMasterLibrarin{
     require(!librarianExists[_newLibrarian], "This address is already a librarian");
     librarians.push(_newLibrarian);
     librarianExists[_newLibrarian] = true;
    }
    // Function to Add Books
    function AddBooks(
        bytes memory _bookTitle,
        bytes memory _bookAuthor,
        bytes memory _bookCategory,
        uint256 _bookPublicationDate,
        uint256 _bookRackNumber,
        uint256 _bookCopiesAvailable
        ) public OnlyLibraryAdminStaff {                    
            require(!books[bookId].hasexist,"already Exist");
            Books storage book = books[bookId];
            book.Booksid = bookId;
            book.bookTitle= _bookTitle;
            book.bookAuthor = _bookAuthor;
            book.bookCategory= _bookCategory;
            book.bookPublicationDate= _bookPublicationDate;
            book.bookRackNumber = _bookRackNumber;
            book.bookCopiesAvailable = _bookCopiesAvailable;
            book.hasexist = true;
            book.bookStatus = Status.Available;
            bookCount++;
            bookId++;
            emit AddBook(bookId, _bookAuthor, _bookCategory, _bookPublicationDate, _bookRackNumber, _bookCopiesAvailable);
        }
        // Function to Add members 
    function Addmembers( 
        bytes memory _memberName,
        bool _registration)internal{
            Members storage member = membersaddress[MembersId];
            member.memberName = _memberName;
            membersaddress[MembersId].addressById[MembersId] = msg.sender;
            membersaddress[MembersId].memberremove[MembersId][msg.sender] = true;
            require(!members[msg.sender], "User is already a member");
            members[msg.sender] = true;
            member.registration = _registration;  
            member.Memberhasexsit = true;
            member.memberaddress = msg.sender;
             memberexsit[MembersId][msg.sender].Memberhasexsit = true;
            MembersId++; 
             emit AddMembers(MembersId, _memberName, msg.sender);  
             }
    //Function to delete Member
    function DeleteMmeber(uint id,address member) public OnlyLibraryAdminStaff{
                require(membersaddress[id].Memberhasexsit==true);
                memberexsit[id][member].Memberhasexsit = false;
                membersaddress[id].Memberhasexsit= false;
                members[member]= false;
                delete membersaddress[id];
                emit memberdeleted(id,member);
             }
        // Function to UpdateBooks in library
    function UpdateBooks( uint _bookId,
        bytes memory _bookTitle,
        bytes memory _bookAuthor,
        bytes memory _bookCategory,
        uint256 _bookPublicationDate,
        uint256 _bookRackNumber, 
        uint256 _bookCopiesAvailable) public OnlyLibraryAdminStaff {
            require(books[_bookId].hasexist == true,"Book are Not Exist");
            Books storage book = books[_bookId];
            book.bookTitle= _bookTitle;
            book.bookAuthor = _bookAuthor;
            book.bookCategory= _bookCategory;
            book.bookPublicationDate= _bookPublicationDate;
            book.bookRackNumber = _bookRackNumber;
            book.bookCopiesAvailable = _bookCopiesAvailable;
            book.hasexist = true;
            book.bookStatus = Status.Available;
            checkbook[_bookAuthor] = book;
            checkbook[_bookCategory] = book;
            checkbook[_bookTitle] = book;
            books[_bookPublicationDate] = book;

            emit UpdateBook(bookId, _bookAuthor, _bookCategory, _bookPublicationDate, _bookRackNumber, _bookCopiesAvailable);
        }
        // Function to Delete Books From Library
    function DeleteBooks( uint256 _bookId
        ) public OnlyLibraryAdminStaff {
            
            require(books[_bookId].hasexist == true,"Book are Not Exist");
            delete books[_bookId];
            emit DeleteBook(_bookId);
        }      
        // Function For Member Registration    
    function MemberRegistration(
        bytes memory _memberName) public{
      
            uint RegistrationFee = 5;
            require(balanceOf(msg.sender)>=RegistrationFee,"Insufficient Balance");
            require(RegistrationFee == RegistrationFee,"First Pay Registration Fee & Fee is 5 Token");
                _transfer(msg.sender, address(this),5);
                Addmembers(_memberName, true);
                memberIdCounter++;        
        }
        // Function to Mint ERC20 Magnus Token
    function MintToken(uint value)public{
            _mint(msg.sender,value);
        }
        //Function to update Members Data
        function Updatemembers(  uint memberid,
        bytes memory _newmemberName)public OnlyLibraryAdminStaff {
             require(membersaddress[memberid].Memberhasexsit==true,"Member are Not Exit");
            Members storage member = membersaddress[memberid];
            member.memberName = _newmemberName;
            // member.registration = _registration;  
             emit Updatemember(memberid,_newmemberName);
             }

        // Function to IssueBooks 
    function IssueBooks(uint BookId,uint _MembersId)public OnlyLibraryAdminStaff {
            require(membersaddress[_MembersId].Memberhasexsit==true,"Member are Not Exit");
            require(books[BookId].hasexist == true,"Book are Not Exist");
            require(
            Bookstatus[_MembersId][membersaddress[BookId].addressById[_MembersId]][BookId] != Status.Borrowed,
            "Please return the book first."
        );
            Members storage member = membersaddress[_MembersId];
              Books storage book = books[BookId];
            require(member.booksCheckedOut.length< MaxBookLimit,"Books Limit Completed");
              require(book.bookCopiesAvailable>0,"Book are not available");
              book.bookCopiesAvailable--;
              book.bookDueDate = block.timestamp + MaxTimeLimit;
              member.booksCheckedOut.push(BookId);
                if (Bookstatus[_MembersId][msg.sender][BookId] != Status.Returned) {
            books[BookId].allBorrowers.push(msg.sender);
        }
        if(book.bookCopiesAvailable ==0){
            books[BookId].bookStatus = Status.NotAvailable;
        }
        Bookstatus[_MembersId][membersaddress[BookId].addressById[_MembersId]][BookId] = Status.Borrowed;
        book.Borrowed++;
        member.numBooksBorrowed++;
         
        emit IssueBook(BookId, MembersId, msg.sender);
        }

    function getMemberAddressById(uint256 _id) external view returns (address) {
        require(membersaddress[_id].Memberhasexsit==true,"Mmember are Not Exit");
        return membersaddress[_id].addressById[_id];
    }
    // Function to Return Books
    function ReturnBook(uint BookId,uint _MembersId) public OnlyLibraryAdminStaff{
        require(books[BookId].hasexist == true,"Book are Not Exist");
        require(membersaddress[_MembersId].Memberhasexsit==true,"Mmember are Not Exit");
         require(
            Bookstatus[_MembersId][membersaddress[BookId].addressById[_MembersId]][BookId] == Status.Borrowed,
            "You don't currently have this book."
        );
        Bookstatus[_MembersId][membersaddress[BookId].addressById[_MembersId]][BookId]  = Status.Returned;
        Members storage member = membersaddress[_MembersId];
        Books storage book = books[BookId];
        if(block.timestamp <= book.bookDueDate){     
        for (uint256 i = 0; i < member.booksCheckedOut.length; i++) {

            if (member.booksCheckedOut[i] == BookId) {
                member.booksCheckedOut[i] = member.booksCheckedOut[member.booksCheckedOut.length - 1];
                member.booksCheckedOut.pop();
                break;
        }}}
        if(block.timestamp>book.bookDueDate ){
             for (uint256 i = 0; i < member.booksCheckedOut.length; i++) {

            if (member.booksCheckedOut[i] == BookId) {
                member.booksCheckedOut[i] = member.booksCheckedOut[member.booksCheckedOut.length - 1];
                member.booksCheckedOut.pop();
                break;
        }}
            PayFine(BookId,_MembersId);    
        }
          book.Borrowed--;
          member.numBooksBorrowed--;
          book.bookDueDate = 0; 
          book.bookStatus = Status.Available;
          book.bookCopiesAvailable++;
          MaxBookLimit--;
          emit ReturnBooks(BookId, MembersId, member.memberaddress);
        } 
        //Internal Function to Pay Fine 
    function PayFine(uint BookId,uint _MembersId) internal{
             Members storage member = membersaddress[_MembersId];
             Books storage book = books[BookId];
            require(block.timestamp>book.bookDueDate );
            require(balanceOf(member.memberaddress)>=Fine,"Member have insufficient balance For pay the fine");
            _transfer(member.memberaddress, address(this),Fine);
            emit FinePaid(member.memberaddress, Fine);
        }
        //Function to reserve book
    function ReserveBook(uint _BookId,uint _memberId) public OnlyReservation{
        require(books[_BookId].hasexist == true,"Book are Not Exist");
        require(membersaddress[_memberId].Memberhasexsit==true,"Memmber are Not Exit");
             Books storage book = books[_BookId];
        require( books[_BookId].bookStatus == Status.NotAvailable,"Book available, no need to reserve");     
        require(book.bookCopiesAvailable == 0, "Book available, no need to reserve");
        require(book.bookReservedBy != msg.sender, "Already reserved by the same member");
        book.bookReservedBy = msg.sender;
        membersaddress[_memberId].reservedBooks.push(_BookId);
         books[_BookId].bookStatus = Status.Reserved;
        emit ReserveBooks(_BookId, _memberId);
        } 
 
        //function to view books
    function ViewBooks() external view returns (Books[] memory) {
        uint256 availableBooksCount = 1;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (books[i].bookCopiesAvailable > 0) {
                availableBooksCount++;       
                  }
        }
        Books[] memory availableBooks = new Books[](availableBooksCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (books[i].bookCopiesAvailable > 0) {
                availableBooks[index] = books[i];
                index++;
            } }
        return availableBooks;
    }
     // Function to search books by ID
     function searchBookById(uint256 _bookid) external view returns (Books[] memory) {
        require(_bookid > 0 && _bookid <= bookCount, "Invalid book ID");
        require(books[_bookid].hasexist == true,"Book are Not Exist");
        uint[] memory foundBook =  searchBooksById(_bookid);
       return fetchBookDetails(foundBook);
    }
     // Function to search books by title 
    function searchBookByTitle(bytes memory _title) external view returns (Books[] memory) {
        uint256[] memory bookIds = searchBooksByTitle(_title);
        return fetchBookDetails(bookIds);
    }
    // Function to search books by author 
    function searchBookByAuthor(bytes memory _author) external view returns (Books[] memory) {
        uint256[] memory bookIds = searchBooksByAuthor(_author);
        return fetchBookDetails(bookIds);
    }

    // Function to search books by category
    function searchBookByCategory(bytes memory _category) external view returns (Books[] memory) {
        uint256[] memory bookIds = searchBooksByCategory(_category);
        return fetchBookDetails(bookIds);
    }

    // Function to search books by publication date
    function searchBookByPublicationDate(uint256 _publicationDate) external view returns (Books[] memory) {
        uint256[] memory bookIds = searchBooksByPublicationDate(_publicationDate);
        return fetchBookDetails(bookIds);
    }

     // Internal function to search books by title 
    function searchBooksByTitle(bytes memory _title) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bookCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (compareStrings(books[i].bookTitle, _title)) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // Internal function to search books by author 
    function searchBooksByAuthor(bytes memory _author) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bookCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (compareStrings(books[i].bookAuthor, _author)) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // Internal function to search books by category 
    function searchBooksByCategory(bytes memory _category) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bookCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (compareStrings(books[i].bookCategory, _category)) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // Internal function to search books by publication date 
    function searchBooksByPublicationDate(uint256 _publicationDate) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bookCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (books[i].bookPublicationDate == _publicationDate) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    // Internal function to search books by ID
    function searchBooksById(uint256 _bookId) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bookCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= bookCount; i++) {
            if (books[i].Booksid == _bookId) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    // Internal function to Fetch Books Details
     function fetchBookDetails(uint256[] memory _bookIds) internal view returns (Books[] memory) {
        Books[] memory result = new Books[](_bookIds.length);
        for (uint256 i = 0; i < _bookIds.length; i++) {
            result[i] = books[_bookIds[i]];
        }
        return result;
    }   
    // Internal function to compare two strings
    function compareStrings(bytes memory a, bytes memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }     
    } 
