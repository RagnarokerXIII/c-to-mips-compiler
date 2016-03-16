%{
#include <iostream>
#include <cstdlib>
#include <string>
#include <stack>
#include "ast.h"
#include "ast.cpp"

int yylex();
int yyerror(const char* s);
char* identifier_value;
int scope_counter = 0;
int is_function = 0;
std::stack<Expression*> mystack;
mipsRegisters mips32;

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

%type <str> declarator 

%type <exp> additive_expression multiplicative_expression cast_expression unary_expression postfix_expression primary_expression
expression
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



primary_expression : IDENTIFIER     {$$ = new IdentifierExpression($1);mystack.push($$);}      
                   | INT_NUM        {$$ = new ConstantExpression($1);mystack.push($$);}             
                   | STRINGLITERAL        
                   | '(' expression ')'
                   ;

/*
CONSTANT : INT_NUM                        
         | FLOAT_NUM                     
         ;
*/

assignment_operator : '=' 
                    | MUL_ASSIGNMENT 
                    | DIV_ASSIGNMENT
                    | MOD_ASSIGNMENT
                    | ADD_ASSIGNMENT
                    | SUB_ASSIGNMENT
                    | LEFT_ASSIGNMENT
                    | RIGHT_ASSIGNMENT
                    | AND_ASSIGNMENT
                    | XOR_ASSIGNMENT
                    | OR_ASSIGNMENT
                    ;



constant_expression : conditional_expression
                    ;


/* ============== Expression Implementation ====================== */


expression : assignment_expression                        { 
                                                            $$ = new UnaryExpression($1,"assignment_expression");

                                                          }
           | expression ',' assignment_expression         
           ; 

/* ================ assignment expression =================== */

assignment_expression : conditional_expression            { $$ = new UnaryExpression($1,"conditional_expression"); mystack.push($$);}
                      | unary_expression assignment_operator assignment_expression  {
                                                                                      Expression* exp1,exp2;
                                                                                      std::string var;
                                                                                      int x;
                                                                                      bool testCase = false;
                                                                                      exp1 = $1;
                                                                                      exp2 = $3;
                                                                                      while(!testCase){
                                                                                       if(exp1->getType() == "Identifier"){
                                                                                          var = exp1->getName();
                                                                                          testCase = true;
                                                                                        }
                                                                                        else{
                                                                                          exp1 = exp1->getNext();
                                                                                        }
                                                                                        
                                                                                      }
                                                                                      testCase = false;
                                                                                      while(!testCase){
                                                                                        if(exp2->getType() == "Constant"){
                                                                                          x = exp2->getConstant();
                                                                                          testCase = true;
                                                                                        }
                                                                                        else{
                                                                                          exp2 = exp2->getNext();
                                                                                        }
                                                                                        
                                                                                      }

                                                                                      int finder = mips32.registerLookup(var);
                                                                                      if(finder == -1){
                                                                                        std::cout << "syntax error" << std::endl;
                                                                                        return -1;
                                                                                      }
                                                                                      else{
                                                                                        mips32.Bind(x,finder,var);
                                                                                      }
                                                                                      mips32.printAllRegisters();
                                                                                    }
                      ;

/* ===================================== */


conditional_expression : logical_or_expression             { $$ = $1;}
                       | logical_or_expression '?' expression ':' conditional_expression
                       ;

unary_expression : postfix_expression                      { $$ = $1;}
                 | INC_OPERATOR unary_expression
                 | DEC_OPERATOR unary_expression
                 | unary_operator cast_expression
                 | SIZEOF unary_expression
                 | SIZEOF '(' type_name ')'
                 ;


/* ================ assignment expression recurse tree units =================== */

logical_or_expression : logical_and_expression                                    { $$ = $1;}
                      | logical_or_expression OR_OPERATOR logical_and_expression
                      ;


postfix_expression : primary_expression                                           { $$ = $1;}
                   | postfix_expression '[' expression ']'
                   | postfix_expression '(' ')'
                   | postfix_expression '(' argument_expression_list ')'
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

cast_expression : unary_expression                                      { $$ = $1;}
                | '(' type_name ')' cast_expression
                ;


/* ===================================== */


logical_and_expression : inclusive_or_expression                         { $$ = $1;}
                       | logical_and_expression AND_OPERATOR inclusive_or_expression
                       ;

argument_expression_list : assignment_expression
                         | argument_expression_list ',' assignment_expression
                         ;



/* ===================================== */


inclusive_or_expression : exclusive_or_expression                         { $$ = $1;}
                        | inclusive_or_expression '|' exclusive_or_expression
                        ;

/* ===================================== */

exclusive_or_expression : and_expression                                  { $$ = $1;}
                        | exclusive_or_expression '^' and_expression
                        ;

/* ===================================== */

and_expression : equality_expression                                      { $$ = $1;}
               | and_expression '&' equality_expression
               ;

/* ===================================== */

equality_expression : relational_expression                               { $$ = $1;}
                    | equality_expression EQ_OPERATOR relational_expression
                    | equality_expression NE_OPERATOR relational_expression
                    ;

/* ===================================== */

relational_expression : shift_expression                                  { $$ = $1;}
                      | relational_expression '<' shift_expression        
                      | relational_expression '>' shift_expression        
                      | relational_expression LE_OPERATOR shift_expression 
                      | relational_expression GE_OPERATOR shift_expression
                      ;

/* ===================================== */

shift_expression : additive_expression                                   { $$ = $1;}
                 | shift_expression LEFT_OPERATOR additive_expression
                 | shift_expression RIGHT_OPERATOR additive_expression
                 ;

/* ===================================== */

additive_expression : multiplicative_expression                            { $$ = $1;}
                    | additive_expression '+' multiplicative_expression    { $$ = new BinaryExpression($1,"+",$3);mystack.push($$);
                                                                              std::cout << "ADDITION COMPLETE" << std::endl;
                                                                           }
                    | additive_expression '-' multiplicative_expression    { $$ = new BinaryExpression($1,"-",$3);mystack.push($$);}
                    ;

/* ===================================== */

multiplicative_expression : cast_expression                                { $$ = $1;}   
                          | multiplicative_expression '*' cast_expression  { $$ = new BinaryExpression($1,"*",$3);mystack.push($$);}
                          | multiplicative_expression '/' cast_expression  { $$ = new BinaryExpression($1,"/",$3);mystack.push($$);}
                          | multiplicative_expression '%' cast_expression  { $$ = new BinaryExpression($1,"%",$3);mystack.push($$);}
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

statement : labeled_statement         {$$ = $1;}      
          | compound_statement        {$$ = $1;}
          | expression_statement      {$$ = $1;}
          | selection_statement       {$$ = $1;}
          | iteration_statement       {$$ = $1;}
          | jump_statement            {$$ = $1;}
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
               | RETURN expression ';'
               ;

/* ============================ Statement recursion tree units ============================= */

statement_list : statement                   {$$ = $1;}
               | statement_list statement     
               ;

declaration_list : declaration                {$$ = $1;}
                 | declaration_list declaration
                 ;


/* ================ Declaration ========================= */


declaration : declaration_specifiers ';'
            | declaration_specifiers init_declarator_list ';'      {


                                                                      for(int i=0;i<scope_counter;i++){
                                                                        std::cout << "    " ;
                                                                      }
                                                                      std::cout << "VARIABLE : " << identifier_value << std::endl;
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

init_declarator : declarator
                | declarator '=' initializer                                            {std::cout << "hohohoohoh" << std::endl;}
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

direct_declarator : IDENTIFIER                                                      {identifier_value = $1;}
                  | '(' declarator ')'                                               
                  | direct_declarator '[' constant_expression ']'                         
                  | direct_declarator '[' ']'                               
                  | direct_declarator function_name parameter_type_list ')'         {std::cout << "asdasdasdasdsa" << std::endl;}         
                  | direct_declarator function_name identifier_list ')'             {std::cout << "sqqqqqqqq" << std::endl;}
                  | direct_declarator function_name ')'                             {std::cout << "pppppppppppppppp" << std::endl;}
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
                                                                              mips32.printAllRegisters();
                                                                              for(int i=0;i<scope_counter;i++){
                                                                                std::cout << "    " ;
                                                                              }
                                                                              std::cout << "    PARAMS : " << $2 << std::endl;
                                                                          }
                      | declaration_specifiers
                      ;

identifier_list : IDENTIFIER                                                                        
                | identifier_list ',' IDENTIFIER                                                    
                ;


/* ========= initializer ======== */

initializer : assignment_expression
            | start_scope initializer_list end_scope
            | start_scope initializer_list ',' end_scope
            ;

initializer_list : initializer
                 | initializer_list ',' initializer
                 ;


/* ================== function definitions ====================== */

function_definition : declaration_specifiers declarator declaration_list compound_statement   
                    | declaration_specifiers declarator compound_statement                    {std::cout << "function definition compound statemnet" << std::endl;}
                    | declarator declaration_list compound_statement                          
                    | declarator compound_statement                                         
                    ;


/* ====================== stdout handlers ====================== */

start_scope : '{'        {
                            for(int i=0;i<scope_counter;i++){
                              std::cout << "    " ;
                            }
                            scope_counter++; std::cout << "SCOPE" << std::endl;
                         }
            ;

end_scope : '}'          {scope_counter--;}
          ;


function_name : '('   {
                        for(int i=0;i<scope_counter;i++){
                          std::cout << "    " ;
                        }
                        std::cout << "FUNCTION : " << identifier_value << std::endl;
                      }        
              ;

/* ====================== stdout handlers END ====================== */

%%

int yyerror(const char* s){ 
    std::cout << s << std::endl;
    return -1;
}

int main(void) {
  yyparse();
}
