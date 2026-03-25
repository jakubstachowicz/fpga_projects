%{
#include "parser.tab.h"
#include <stdlib.h>
%}

%option noyywrap

%%

">>> UART RECEIVED:"[ \t]+[0-9]+ {
    const char *p = yytext;
    while (*p && (*p < '0' || *p > '9')) {
        p++;
    }
    yylval.val = atoi(p);
    return UART_MSG;
}

\n
.

%%
