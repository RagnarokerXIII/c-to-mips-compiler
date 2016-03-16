#include <iostream>
#include <cstdlib>
#include <string>
#include <vector>
#ifndef AST_H
#define	AST_H

/*
IMPORTANT : consider using int counts to traverse the AST later on;
create a pretty print function that traverses through the entire tree!
]

http://stackoverflow.com/questions/10739923/what-is-in-bison
REVELATION : $$ is returned as $x !

Example:
shift_expression : additive_expression                                   { $1->test_print();}
this means that $1 is whatever I returned to $$ for additive expressions!,
in this case $$ = new Plus !


Consider using smart pointers
http://stackoverflow.com/questions/106508/what-is-a-smart-pointer-and-when-should-i-use-one



TODO:
Statements
Register tracking - look at notes
CodeGen - look at phone pic, notes

1. track all declared variables, int X ..., only 2 places where declarations like int X can occur - declaration and parameter declaration
*/

// Base node class for AST
class Node{
public:
	// virtual void postTraversal(Expression* exp1);
	virtual ~Node() {}
};

// Expressions

class Expression : public Node{
public:
	// const Type * getType();
	// virtual evaluate() = 0;
	// Render using current identifier-register bindings in ctxt
	// void codeGen(const Context & ctxt) const;
	virtual std::string getType();
	virtual void printer();

};

// generic class for plus,minus for 2 operands and 1 operator
class BinaryExpression : public Expression{
private:
	Expression *left = NULL;
	Expression *right = NULL;
	std::string opCode;
public:
	BinaryExpression(Expression *l,std::string op,Expression *r): left(l),opCode(op),right(r) {}
	const Expression *getLeft() const;
	std::string getOperator() const;
	const Expression *getRight() const;
	std::string getType();
	void printer();
	void codeGen();
};


class IdentifierExpression : public Expression{
	std::string id;
public:
	std::string getName() const;
	IdentifierExpression(std::string str1): id(str1) {}
	std::string getType();
	void printer();
};

class ConstantExpression : public Expression{
	int num;
public:
	int getConstant() const;
	ConstantExpression(const int &num1) : num(num1) {}
	std::string getType();
	void printer();
};


// Statements

class Statement : public Node{
	// Render using current identifier-register bindings in ctxt
	// Context renderAssembly(const Context & ctxt) const;
	virtual void print() {}
};

class LabeledStatement : public Statement{
	
};

class CompoundStatement : public Statement{
	/*int getDeclarationCount() const;
	const Declaration *getDeclaration(int i) const;
	int getStatementCount() const;
	const Statement *getStatement(int i) const;*/
};

class ExpressionStatement : public Statement{
	const Expression *getExpression() const;
};

class SelectionStatement : public Statement{

};


/*

selection_statement : IF '(' expression ')' statement
                    | IF '(' expression ')' statement ELSE statement
                    | SWITCH '(' expression ')' statement
                    ;

*/                

class IfStatement : public Statement{
	Expression* exp;
	Statement* state;
public:
	const Expression *getCondition() const;
	const Statement *getStatement() const;
	IfStatement(Expression* exp1,Statement* state1): exp(exp1), state(state1) {}
	// IfStatement(Expression* exp1,Statement* state1,Statement* state2):
};


class IterationStatement : public Statement{
	
};

class JumpStatement : public Statement{
	
};

// "struct with properties associated with a register"
class Register{
public:
	Register() {}
	Register(int v,std::string var,bool t): value(v),varName(var),inUse(t) {}
	int value = 0;
	std::string varName = "";
	bool inUse = false;			// can't use 0 to check if register is in use as register can be 
};

// Register handling
// declaration - int a = 3; should use a new register
// usage - a = 5; should use an existing register regardless of scope as tested in C90 ( except in the case of function calls)
class mipsRegisters{
	std::vector<Register> registers;	// sets 31 registers to 0,make this public?
public:
	mipsRegisters():registers(31) {
		std::cout << "initializing mips32 registers" << std::endl;
	}
	Register getValue(const int &registerName);
	void Bind(const int &val,const int &registerName,const std::string &var);
	int registerLookup(const std::string &varName);
	void clearRegisters();
	void printAllRegisters();
	int findEmptyRegister();
};


/*
// returns the biggest available register
int mipsRegisters::Lookup(){
	int available;
	for(int i=15;i<23;i++){
		if(in_use){
			available = i;
		}
	}
	return available;
}
*/


#endif

