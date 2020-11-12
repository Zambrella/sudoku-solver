import 'package:flutter/material.dart';
import 'package:sudoku_solver/constants/enums.dart';
import 'package:sudoku_solver/models/board_square.dart';
import 'package:sudoku_solver/models/position_model.dart';

class SudokuGrid extends ChangeNotifier {
  List<List<BoardSquare>> userBoard;
  int width;
  int height;
  int selectedNumber = 0;
  SolveScreenStates solveScreenStates = SolveScreenStates.Idle;

  // Generic constructor
  SudokuGrid({this.userBoard, this.width, this.height});

  // Named constructor to build a blank board
  SudokuGrid.blank(int rowCount, int columnCount) {
    this.userBoard = List.generate(
      rowCount,
      (int row) => List.generate(
        columnCount,
        (int column) => BoardSquare(position: Position(x: row, y: column), value: 0),
      ),
    );
    this.width = rowCount;
    this.height = columnCount;
  }

  SudokuGrid.fromTemplate(List<List<BoardSquare>> templateBoard) {
    userBoard = templateBoard;
    this.width = 9;
    this.height = 9;
  }

  // Cycle through each board square and set it's value to 0
  void resetBoard() {
    userBoard.forEach((row) {
      row.forEach((boardSquare) {
        boardSquare.value = 0;
      });
    });
    this.selectedNumber = 0;
    solveScreenStates = SolveScreenStates.Idle;
    notifyListeners();
  }

  // Function to fill a given square with numbers 1 - 9 and produce a list of boards
  Future<void> solveBoard(List<List<BoardSquare>> originalBoard) async {
    solveScreenStates = SolveScreenStates.Loading;
    notifyListeners();
    // Duplicate board
    List<List<BoardSquare>> board = createNewBoard(originalBoard);
    // Flatten the board
    List<BoardSquare> flatBoard = board.expand((element) => element).toList();

    // Get the position of the next blank space
    Position position = getNextEmptySquare(flatBoard);

    // Pass the position and board to create new boards
    List<List<List<BoardSquare>>> newBoards = createNewBoards(position, board);

    // If board is valid add to valid boards, if not, do recursion
    for (List<List<BoardSquare>> board in newBoards) {
      // First need to make sure they're a legal board
      // If legal continue, if not, stop
      if (checkLegal(board) == true) {
        // See if board is empty
        // If empty, iterate. If not the board is complete
        if (hasBlanks(board) == false) {
          userBoard = board;
          solveScreenStates = SolveScreenStates.Idle;
          notifyListeners();
          break;
        } else {
          solveBoard(board);
        }
      } else {
        // do nothing
      }
    }
  }

  // Helper function to find the position of the next empty square
  Position getNextEmptySquare(List<BoardSquare> flatBoard) {
    BoardSquare square = flatBoard.firstWhere((element) => element.value == 0);
    return square.position;
  }

  // Helper function to fill a given position with the numbers 1 - 9 and return the list of Boards
  List<List<List<BoardSquare>>> createNewBoards(Position position, List<List<BoardSquare>> board) {
    // Variable to hold new boards
    List<List<List<BoardSquare>>> updatedBoards = [];

    // Use position to replace list at given index
    for (int i = 1; i < 10; i++) {
      // Duplicate board
      List<List<BoardSquare>> newBoard = createNewBoard(board);
      // Update value of new board
      newBoard[position.x][position.y].value = i;
      // Add new board to list
      updatedBoards.add(newBoard);
    }
    return updatedBoards;
  }

  // Function to check if the board has any blanks. Used to check if board is solved.
  bool hasBlanks(List<List<BoardSquare>> board) {
    bool noBlanks = true;
    // Iterate through the board to see if any value is equal to 0
    // If a 0 is found, it means there is still blank spaces
    for (List<BoardSquare> row in board) {
      noBlanks = row.any((element) => element.value == 0);
    }
    return noBlanks;
  }

  // Function to check that each sublist has a unique number
  bool checkLegal(List<List<BoardSquare>> board) {
    List<List<BoardSquare>> subsets = createFullSublist(board);
    bool isUnique = true;
    for (List<BoardSquare> boardList in subsets) {
      List<int> set = [];
      // Check if values are unique in a given sublist
      // Todo: It would be helpful if the function could highlight the offending square
      for (BoardSquare square in boardList) {
        if (set.contains(square.value) == true && square.value != 0) {
          isUnique = false;
          break;
        } else {
          set.add(square.value);
        }
      }
    }
    return isUnique;
  }

  // Function to join all sub lists into one big list which can iterated over to check for duplicate numbers
  List<List<BoardSquare>> createFullSublist(List<List<BoardSquare>> board) {
    List<List<BoardSquare>> combinedList = [];
    List<List<BoardSquare>> rows = getSublistOfRows(board);
    List<List<BoardSquare>> columns = getSublistOfColumns(board);
    List<List<BoardSquare>> threeXThree = getSublistThreeXThree(board);
    combinedList = rows + columns + threeXThree;
    return combinedList;
  }

  // Function to get a list of Rows. This is easy.
  List<List<BoardSquare>> getSublistOfRows(List<List<BoardSquare>> board) {
    List<List<BoardSquare>> _listOfRows = [];
    for (int i = 0; i < width; i++) {
      _listOfRows.add(board[i]);
    }
    return _listOfRows;
  }

  // Function to get a list of Columns. This was harder because it required nested for loops
  List<List<BoardSquare>> getSublistOfColumns(List<List<BoardSquare>> board) {
    List<List<BoardSquare>> _listOfColumns = [];
    for (int i = 0; i < height; i++) {
      List<BoardSquare> _listOfBoardSquares = [];
      for (int j = 0; j < width; j++) {
        _listOfBoardSquares.add(board[j][i]);
      }
      _listOfColumns.add(_listOfBoardSquares);
    }
    return _listOfColumns;
  }

  // Function to create list of the small 3x3 grids
  List<List<BoardSquare>> getSublistThreeXThree(List<List<BoardSquare>> board) {
    List<List<BoardSquare>> _listOfThreeXThree = [];
    for (int i = 0; i < height; i += 3) {
      for (int j = 0; j < width; j += 3) {
        List<BoardSquare> _subListOfBoardSquares = [];
        _subListOfBoardSquares.add(board[i][j]);
        _subListOfBoardSquares.add(board[i][j + 1]);
        _subListOfBoardSquares.add(board[i][j + 2]);
        _subListOfBoardSquares.add(board[i + 1][j]);
        _subListOfBoardSquares.add(board[i + 1][j + 1]);
        _subListOfBoardSquares.add(board[i + 1][j + 2]);
        _subListOfBoardSquares.add(board[i + 2][j]);
        _subListOfBoardSquares.add(board[i + 2][j + 1]);
        _subListOfBoardSquares.add(board[i + 2][j + 2]);
        _listOfThreeXThree.add(_subListOfBoardSquares);
      }
    }
    return _listOfThreeXThree;
  }

  // Helper function to create a new board from existing board
  List<List<BoardSquare>> createNewBoard(List<List<BoardSquare>> oldBoard) {
    List<List<BoardSquare>> newBoard = List.generate(
      this.width,
      (int row) => List.generate(
        this.height,
        (int column) => BoardSquare(position: Position(x: row, y: column), value: oldBoard[row][column].value),
      ),
    );
    return newBoard;
  }

  // Get a specific board square given a coordinate
  // Currently unused but thought it might be useful
  BoardSquare getBoardSquareAtPosition(int x, int y) {
    return userBoard[x][y];
  }

  void updateSelectedNumber(int newNumber) {
    this.selectedNumber = newNumber;
    notifyListeners();
  }

  String toString() {
    return userBoard[0].toString() +
        '\n' +
        userBoard[1].toString() +
        '\n' +
        userBoard[2].toString() +
        '\n' +
        userBoard[3].toString() +
        '\n' +
        userBoard[4].toString() +
        '\n' +
        userBoard[5].toString() +
        '\n' +
        userBoard[6].toString() +
        '\n' +
        userBoard[7].toString() +
        '\n' +
        userBoard[8].toString();
  }
}