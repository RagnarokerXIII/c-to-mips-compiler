%{
#include <iostream>
#include <cstdlib>
#include <string>
#include <sstream>
#include <stack>
#include "ast.h"
#include "ast.cpp"

int yylex();
int yyerror(const char* s);
char* identifier_value;
int scope_counter = 0;
int is_function = 0;
std::vector<Expression*> completeTree;
std::stack<int> mystack;
mipsRegisters mips32;
bool isMinus = false;
bool debugMode = true;
std::string functionName;

%}

%union 
{
        int number;
        float float_num;
        char* str;
        class Expression* exp;
}

%token <number> INT_NUM

%token <float_num> FLOAT_NUM

%token <str> IDENTIFIER


%token CHAR_CONST STRINGLITERAL SIZEOF

/* keywords */

%token AUTO DOUBLE INT STRUCT BREAK ELSE LONG SWITCH CASE ENUM REGISTER TYPEDEF CHAR EXTERN RETURN UNION CONST FLOAT SHORT UNSIGNED CONTINUE FOR SIGNED VOID DEFAULT GOTO VOLATILE DO IF STATIC WHILE


/* operators */

%token ELLIPSIS 

%token PTR_OPERATOR INC_OPERATOR DEC_OPERATOR LEFT_OPERATOR RIGHT_OPERATOR LE_OPERATOR GE_OPERATOR EQ_OPERATOR NE_OPERATOR

%token AND_OPERATOR OR_OPERATOR MUL_ASSIGNMENT DIV_ASSIGNMENT MOD_ASSIGNMENT ADD_ASSIGNMENT

%token SUB_ASSIGNMENT LEFT_ASSIGNMENT RIGHT_ASSIGNMENT AND_ASSIGNMENT

%token XOR_ASSIGNMENT OR_ASSIGNMENT 

%type <str> declarator '(' ')'

%type <str> '='
MUL_ASSIGNMENT
DIV_ASSIGNMENT
MOD_ASSIGNMENT
ADD_ASSIGNMENT
SUB_ASSIGNMENT
LEFT_ASSIGNMENT 
RIGHT_ASSIGNMENT
AND_ASSIGNMENT  
XOR_ASSIGNMENT  
OR_ASSIGNMENT 
assignment_operator

%type <exp> additive_expression multiplicative_expression cast_expression unary_expression postfix_expression primary_expression expression
assignment_expression
conditional_expression
logical_or_expression
logical_and_expression
inclusive_or_expression
exclusive_or_expression
and_expression
equality_expression
relational_expression
shift_expression
initializer


%%


/* ===================== Parsing START ============================ */

translation_unit : external_declaration
                 | translation_unit external_declaration
                 ;

external_declaration : declaration             
                     | function_definition     
                     ;

/* ===================== Parsing END ============================ */

/* NOTE : all implementations below are partial, REMEMBER to check against spec */



primary_expression : IDENTIFIER     {$$ = new IdentifierExpression($1);completeTree.push_back($$);}      
                   | INT_NUM        {$$ = new ConstantExpression($1);completeTree.push_back($$);}             
                   | STRINGLITERAL        
                   | '(' expression ')' {std::cout << "TODO? Seems to work without new Bracket .... : Open bracket for expressions, eg: (2 - 1)" << std::endl;}
                   ;

/*
CONSTANT : INT_NUM                        
         | FLOAT_NUM                     
         ;
*/

assignment_operator : '='                         {$$ = $1;}
                    | MUL_ASSIGNMENT              {$$ = $1;}              
                    | DIV_ASSIGNMENT              {$$ = $1;}
                    | MOD_ASSIGNMENT              {$$ = $1;}
                    | ADD_ASSIGNMENT              {$$ = $1;}
                    | SUB_ASSIGNMENT              {$$ = $1;}
                    | LEFT_ASSIGNMENT             {$$ = $1;}
                    | RIGHT_ASSIGNMENT            {$$ = $1;}
                    | AND_ASSIGNMENT              {$$ = $1;}
                    | XOR_ASSIGNMENT              {$$ = $1;}
                    | OR_ASSIGNMENT               {$$ = $1;}
                    ;



constant_expression : conditional_expression
                    ;


/* ============== Expression Implementation ====================== */


expression : assignment_expression                        { $$ = new UnaryExpression($1,"assignment_expression"); }
           | expression ',' assignment_expression         { $$ = new BinaryExpression($1,",",$3);}
           ; 

/* ================ assignment expression =================== */

assignment_expression : conditional_expression            { $$ = new UnaryExpression($1,"conditional_expression"); completeTree.push_back($$);}
                      | unary_expression assignment_operator assignment_expression       { 
                                                                                            if(debugMode){
                                                                                              std::cout << "a = 3 + 2..." << std::endl;
                                                                                            }
                                                                                            int counter = 0;
                                                                                            std::string binder;

                                                                                            /* check if identifier $1 exists or not */
                                                                                            bool checker = false;
                                                                                            const Expression * temp1 = $1;
                                                                                            while(!checker){
                                                                                              if(temp1->getType() == "Identifier"){
                                                                                                /* identifier has to exist prior to this */
                                                                                                int v = mips32.registerLookup(temp1->getName());
                                                                                                binder = temp1->getName();
                                                                                                if(v == -1){
                                                                                                  std::cout << "variable has to be declared before usage" << std::endl;
                                                                                                  return -1;
                                                                                                }
                                                                                                else{
                                                                                                  checker = true;
                                                                                                }
                                                                                              }
                                                                                              else{
                                                                                                temp1 = temp1->getNext();
                                                                                              }
                                                                                            }

                                                                                          /* Shunting-yard algorithm */
                                                                                          for(int i=0;i<completeTree.size();i++){
                                                                                              if(completeTree[i]->getType() == "Binary" || completeTree[i]->getType() == "Identifier" || completeTree[i]->getType() == "Constant"){
                                                                                                if(debugMode){
                                                                                                  completeTree[i]->printer();
                                                                                                }
                                                                                                if(completeTree[i]->getType() == "Constant"){
                                                                                                  mystack.push(completeTree[i]->getConstant());
                                                                                                }
                                                                                                else if(completeTree[i]->getType() == "Identifier"){
                                                                                                  // logic to handle identifier conversion
                                                                                                  int y = mips32.registerLookup(completeTree[i]->getName());
                                                                                                  Register r = mips32.getValue(y);
                                                                                                  mystack.push(r.value);
                                                                                                }
                                                                                                else if(completeTree[i]->getType() == "Binary"){
                                                                                                  std::string strOp = completeTree[i]->getOperator();
                                                                                                  int temp_x = mystack.top();
                                                                                                  mystack.pop(); 
                                                                                                  int temp_y = mystack.top();
                                                                                                  mystack.pop();
                                                                                                  int sum = 0;
                                                                                                  if(strOp == "+"){
                                                                                                    sum = temp_y + temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "-"){
                                                                                                    sum = temp_y - temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "*"){
                                                                                                    sum = temp_y * temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "/"){
                                                                                                    sum = temp_y / temp_x;
                                                                                                  }
                                                                                                  mystack.push(sum);
                                                                                                }
                                                                                              }
                                                                                            }
                                                                                            int ans = mystack.top();
                                                                                            int v = mips32.registerLookup(binder);
                                                                                            mips32.Bind(ans,v,binder);
                                                                                            completeTree.clear();
                                                                                            codeGen(v,mips32);
                                                                                            mystack.pop();
                                                                                            if(debugMode){
                                                                                              mips32.printAllRegisters();
                                                                                            }
                                                                                          }

                      ;

/* ===================================== */


conditional_expression : logical_or_expression             { $$ = new UnaryExpression($1,"logical_or_expression");completeTree.push_back($$);}
                       | logical_or_expression '?' expression ':' conditional_expression
                       ;

unary_expression : postfix_expression                      { $$ = new UnaryExpression($1,"postfix_expression");completeTree.push_back($$);}
                 | INC_OPERATOR unary_expression
                 | DEC_OPERATOR unary_expression
                 | unary_operator cast_expression           { std::cout << "TODO: UNARY FOR MINUS" <<std::endl;isMinus = true;}
                 | SIZEOF unary_expression
                 | SIZEOF '(' type_name ')'
                 ;


/* ================ assignment expression recurse tree units =================== */

logical_or_expression : logical_and_expression                                    { $$ = new UnaryExpression($1,"logical_and_expression");completeTree.push_back($$);}
                      | logical_or_expression OR_OPERATOR logical_and_expression
                      ;


postfix_expression : primary_expression                                           { $$ = new UnaryExpression($1,"primary_expression");completeTree.push_back($$);}
                   | postfix_expression '[' expression ']'
                   | postfix_expression '(' ')'
                   | postfix_expression '(' argument_expression_list ')'           { std::cout << "dasdaoihweowqidajd" << std::endl;}
                   | postfix_expression '.' IDENTIFIER
                   | postfix_expression PTR_OPERATOR IDENTIFIER
                   | postfix_expression INC_OPERATOR
                   | postfix_expression DEC_OPERATOR
                   ;

unary_operator : '&'    
               | '*'
               | '+'
               | '-'
               | '~'
               | '!'
               ;

cast_expression : unary_expression                                      { $$ = new UnaryExpression($1,"unary_expression");completeTree.push_back($$);}
                | '(' type_name ')' cast_expression                     
                ;


/* ===================================== */


logical_and_expression : inclusive_or_expression                         { $$ = new UnaryExpression($1,"inclusive_or_expression");completeTree.push_back($$);}
                       | logical_and_expression AND_OPERATOR inclusive_or_expression
                       ;

argument_expression_list : assignment_expression
                         | argument_expression_list ',' assignment_expression
                         ;



/* ===================================== */


inclusive_or_expression : exclusive_or_expression                         { $$ = new UnaryExpression($1,"exclusive_or_expression");completeTree.push_back($$);}
                        | inclusive_or_expression '|' exclusive_or_expression
                        ;

/* ===================================== */

exclusive_or_expression : and_expression                                  { $$ = new UnaryExpression($1,"and_expression");completeTree.push_back($$);}
                        | exclusive_or_expression '^' and_expression
                        ;

/* ===================================== */

and_expression : equality_expression                                      { $$ = new UnaryExpression($1,"equality_expression");completeTree.push_back($$);}
               | and_expression '&' equality_expression
               ;

/* ===================================== */

equality_expression : relational_expression                               { $$ = new UnaryExpression($1,"relational_expression");completeTree.push_back($$);}
                    | equality_expression EQ_OPERATOR relational_expression
                    | equality_expression NE_OPERATOR relational_expression
                    ;

/* ===================================== */

relational_expression : shift_expression                                  { $$ = new UnaryExpression($1,"shift_expression");completeTree.push_back($$);}
                      | relational_expression '<' shift_expression        
                      | relational_expression '>' shift_expression        
                      | relational_expression LE_OPERATOR shift_expression 
                      | relational_expression GE_OPERATOR shift_expression
                      ;

/* ===================================== */

shift_expression : additive_expression                                   { $$ = new UnaryExpression($1,"additive_expression");completeTree.push_back($$);}
                 | shift_expression LEFT_OPERATOR additive_expression
                 | shift_expression RIGHT_OPERATOR additive_expression
                 ;

/* ===================================== */

additive_expression : multiplicative_expression                            { $$ = new UnaryExpression($1,"multiplicative_expression");completeTree.push_back($$);}
                    | additive_expression '+' multiplicative_expression    { $$ = new BinaryExpression($1,"+",$3);completeTree.push_back($$);
                                                                              if(debugMode){
                                                                                std::cout << "ADDITION COMPLETE,recursive testing" << std::endl;

                                                                                    
                                                                              }
                                                                           }
                    | additive_expression '-' multiplicative_expression    { $$ = new BinaryExpression($1,"-",$3);completeTree.push_back($$);std::cout << "SUB" << std::endl; }
                    ;

/* ===================================== */

multiplicative_expression : cast_expression                                { $$ = new UnaryExpression($1,"cast_expression");completeTree.push_back($$);}   
                          | multiplicative_expression '*' cast_expression  { $$ = new BinaryExpression($1,"*",$3);completeTree.push_back($$);std::cout << "MULT" << std::endl;}
                          | multiplicative_expression '/' cast_expression  { $$ = new BinaryExpression($1,"/",$3);completeTree.push_back($$);}
                          | multiplicative_expression '%' cast_expression  { $$ = new BinaryExpression($1,"%",$3);completeTree.push_back($$);}
                          ;

/*
  #incomplete - type_name

    | specifier_qualifier_list abstract_declarator
*/

type_name : specifier_qualifier_list
          ;

specifier_qualifier_list
  : type_specifier specifier_qualifier_list
  | type_specifier
  | type_qualifier specifier_qualifier_list
  | type_qualifier
  ;








/* ============== Statement Implementation ========================== */

statement : labeled_statement               
          | compound_statement
          | expression_statement
          | selection_statement
          | iteration_statement
          | jump_statement
          ;


/* TODO ====== Labeled Statement ======= */

labeled_statement : IDENTIFIER ':' statement
                  | CASE constant_expression ':' statement
                  | DEFAULT ':' statement
                  ;

/* TODO ====== Compound Statement ======= */

compound_statement : start_scope end_scope
                   | start_scope statement_list end_scope                 
                   | start_scope declaration_list end_scope                  
                   | start_scope declaration_list statement_list end_scope     
                   ;

/* OK ====== Expression Statement ======= */

expression_statement : ';'             
                     | expression ';'
                     ;

/* OK ====== Selection Statement ======= */

selection_statement : IF '(' expression ')' statement                                               
                    | IF '(' expression ')' statement ELSE statement
                    | SWITCH '(' expression ')' statement
                    ;



/* OK ====== Iteration Statement ======= */

iteration_statement : WHILE '(' expression ')' statement
                    | DO statement WHILE '(' expression ')' ';'
                    | FOR '(' expression_statement expression_statement expression ')' statement
                    | FOR '(' expression_statement expression_statement ')' statement 
                    ;

/* OK ====== Jump Statement ======= */

jump_statement : GOTO IDENTIFIER ';'
               | CONTINUE ';'
               | BREAK ';'
               | RETURN ';'                 
               | RETURN expression ';'      {
                                              std::cout << "RETURNING..." << std::endl;
                                              for(int i=0;i<completeTree.size();i++){
                                                completeTree[i]->printer();
                                              }


                                            std::cout << "testing 2" << std::endl;}
               ;

/* ============================ Statement recursion tree units ============================= */

statement_list : statement                   
               | statement_list statement     
               ;

declaration_list : declaration
                 | declaration_list declaration
                 ;


/* ================ Declaration ========================= */


declaration : declaration_specifiers ';'
            | declaration_specifiers init_declarator_list ';'      {
                                                                      if(debugMode){
                                                                        for(int i=0;i<scope_counter;i++){
                                                                          std::cout << "    " ;
                                                                        }
                                                                        std::cout << "VARIABLE : " << identifier_value << std::endl;
                                                                      }
                                                                      
                                                                   }
            ;

/* ================ declaration_specifiers ================ */

declaration_specifiers : storage_class_specifier
                       | storage_class_specifier declaration_specifiers
                       | type_specifier
                       | type_specifier declaration_specifiers
                       | type_qualifier
                       | type_qualifier declaration_specifiers
                       ;

storage_class_specifier : TYPEDEF
                        | EXTERN
                        | STATIC
                        | AUTO
                        | REGISTER
                        ;

/* 

  #incomplete - type_specifier

  | struct_or_union_specifier
  | enum_specifier
  | TYPE_NAME - not a token

*/

type_specifier : VOID
               | CHAR
               | SHORT
               | INT                   
               | LONG
               | FLOAT
               | DOUBLE
               | SIGNED
               | UNSIGNED
               ;

type_qualifier : CONST
               | VOLATILE
               ;

/* ============= init_declarator_list ============= */

init_declarator_list : init_declarator                                    
                     | init_declarator_list ',' init_declarator           
                     ;

init_declarator : declarator                                                            {
                                                                                          
                                                                                          int invalid_check = mips32.registerLookup($1);
                                                                                          if(invalid_check != -1){
                                                                                            std::cout << "variable " << $1 << " has already been declared" << std::endl;
                                                                                            return -1;
                                                                                          }
                                                                                          int x = mips32.findEmptyRegister();
                                                                                          if(x == -1){
                                                                                            std::cout << "redeclaration of variable / registers are filled with existing data" << std::endl;
                                                                                            return -1;
                                                                                          }
                                                                                          else{
                                                                                            int f = mips32.findEmptyRegister();
                                                                                            mips32.Bind(0,f,$1);
                                                                                            if(debugMode){
                                                                                              mips32.printAllRegisters();
                                                                                            }
                                                                                          }
                                                                                        }

                | declarator '=' initializer                                            { 
                                                                                            int x = mips32.findEmptyRegister();
                                                                                            if(x == -1){
                                                                                              if(debugMode){
                                                                                                std::cout << "redeclaration of variable / registers are filled with existing data" << std::endl;
                                                                                              }
                                                                                              return -1;
                                                                                            }
                                                                                            else{
                                                                                              for(int i=0;i<completeTree.size();i++){
                                                                                                if(completeTree[i]->getType() == "Constant"){
                                                                                                  mips32.Bind(completeTree[i]->getConstant(),x,$1);
                                                                                                  int counter = 0;
                                                                                                  for(int i=0;i<completeTree.size();i++){
                                                                                                    if(completeTree[i]->getType() == "Binary" ){
                                                                                                      counter++;
                                                                                                    }
                                                                                                  }
                                                                                                }
                                                                                              }
                                                                                              if(debugMode){
                                                                                                mips32.printAllRegisters();
                                                                                              }
                                                                                            }
                                                                                        
                                                                                            /* Shunting-yard algorithm */
                                                                                            if(debugMode){
                                                                                              std::cout << "int a = 3 + 2...init" << std::endl; 
                                                                                            }

                                                                                            for(int i=0;i<completeTree.size();i++){
                                                                                              if(completeTree[i]->getType() == "Binary" || completeTree[i]->getType() == "Identifier" || completeTree[i]->getType() == "Constant"){
                                                                                                if(debugMode){
                                                                                                  completeTree[i]->printer();
                                                                                                }
                                                                                                if(completeTree[i]->getType() == "Constant"){
                                                                                                  mystack.push(completeTree[i]->getConstant());
                                                                                                }
                                                                                                else if(completeTree[i]->getType() == "Identifier"){
                                                                                                  // logic to handle identifier conversion
                                                                                                  int y = mips32.registerLookup(completeTree[i]->getName());
                                                                                                  Register r = mips32.getValue(y);
                                                                                                  mystack.push(r.value);
                                                                                                }
                                                                                                else if(completeTree[i]->getType() == "Binary"){
                                                                                                  std::string strOp = completeTree[i]->getOperator();
                                                                                                  int temp_x = mystack.top();
                                                                                                  mystack.pop(); 
                                                                                                  int temp_y = mystack.top();
                                                                                                  mystack.pop();
                                                                                                  int sum = 0;
                                                                                                  if(strOp == "+"){
                                                                                                    sum = temp_y + temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "-"){
                                                                                                    sum = temp_y - temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "*"){
                                                                                                    sum = temp_y * temp_x;
                                                                                                  }
                                                                                                  else if(strOp == "/"){
                                                                                                    sum = temp_y / temp_x;
                                                                                                  }
                                                                                                  mystack.push(sum);
                                                                                                }
                                                                                              }
                                                                                            }
                                                                                            int ans = mystack.top();
                                                                                            int v = mips32.registerLookup($1);
                                                                                            mips32.Bind(ans,v,$1);
                                                                                            completeTree.clear();
                                                                                            codeGen(v,mips32);
                                                                                            mystack.pop();
                                                                                            if(debugMode){
                                                                                              mips32.printAllRegisters();
                                                                                            }
                                                                                          }
                ;


/* ============== declarator ============ */

declarator : pointer direct_declarator
           | direct_declarator
           ;

pointer : '*'
        | '*' type_qualifier_list
        | '*' pointer
        | '*' type_qualifier_list pointer
        ;

type_qualifier_list : type_qualifier
                    | type_qualifier_list type_qualifier
                    ;

direct_declarator : IDENTIFIER                                                      { identifier_value = $1;

                                                                                    }
                  | '(' declarator ')'                                              
                  | direct_declarator '[' constant_expression ']'                         
                  | direct_declarator '[' ']'                               
                  | direct_declarator function_name parameter_type_list ')'                 
                  | direct_declarator function_name identifier_list ')'             
                  | direct_declarator function_name ')'                             
                  ;



parameter_type_list : parameter_list
                    | parameter_list ',' ELLIPSIS
                    ;

parameter_list : parameter_declaration
               | parameter_list ',' parameter_declaration
               ;

/*   

  #incomplete - parameter_declaration

      | declaration_specifiers abstract_declarator 

*/

parameter_declaration : declaration_specifiers declarator                 {
                                                                              int reg = mips32.findEmptyRegister();
                                                                              mips32.Bind(0,reg,$2);
                                                                              if(debugMode){
                                                                                mips32.printAllRegisters();
                                                                                for(int i=0;i<scope_counter;i++){
                                                                                  std::cout << "    " ;
                                                                                }
                                                                                std::cout << "    PARAMS : " << $2 << std::endl;
                                                                              }
                                                                             
                                                                          }
                      | declaration_specifiers
                      ;

identifier_list : IDENTIFIER                                                                        
                | identifier_list ',' IDENTIFIER                                                    
                ;


/* ========= initializer ======== */

initializer : assignment_expression                              {std::cout << "retty much has to go here" << std::endl;}       
            | start_scope initializer_list end_scope
            | start_scope initializer_list ',' end_scope
            ;

initializer_list : initializer
                 | initializer_list ',' initializer
                 ;


/* ================== function definitions ====================== */

function_definition : declaration_specifiers declarator declaration_list compound_statement   
                    | declaration_specifiers declarator compound_statement                         {mips32.clearRegisters();}
                    | declarator declaration_list compound_statement                          
                    | declarator compound_statement                                         
                    ;


/* ====================== stdout handlers ====================== */

start_scope : '{'        {  /*
                            for(int i=0;i<scope_counter;i++){
                              std::cout << "    " ;
                            }
                            scope_counter++; std::cout << "SCOPE" << std::endl;
                            */
                         }
            ;

end_scope : '}'          {
                            scope_counter--;
                            std::cout << "      j     $31" << std::endl;
                            std::cout << "      nop" << std::endl;
                            std::cout << std::endl;
                            std::cout << "      .end  " << functionName << std::endl;
                          }
          ;


function_name : '('   {
                        for(int i=0;i<scope_counter;i++){
                          std::cout << "    " ;
                        }
                          std::cout << "      .text" << std::endl;
                          std::cout << "      .align 2" << std::endl;
                          std::cout << "      .ent    " << identifier_value << std::endl;
                          std::cout << identifier_value << ":" << std::endl;
                          if(debugMode){
                            std::cout << "FUNCTION : " << identifier_value << std::endl;  
                          }
                          functionName = identifier_value;
                      }        
              ;

/* ====================== stdout handlers END ====================== */

%%


int yyerror(const char* s){ 
    std::cout << s << std::endl;
    return -1;
}

int main(void) {
  std::stringstream ss;
  ss << yyparse();
}


