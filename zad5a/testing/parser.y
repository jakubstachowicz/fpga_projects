%{
#include <stdio.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    int val;
}

%token <val> UART_MSG

%%

stream:
    %empty
    | stream UART_MSG { 
        printf("%c", $2);
        fflush(stdout); 
      }
    ;
%%

void yyerror(const char *s) {
}

int main(void) {
    yyparse();
    return 0;
}
