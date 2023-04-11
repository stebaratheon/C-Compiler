%{
#include<iostream>
#include "symbolinfo.h"
#define YYSTYPE SymbolInfo* 
#include "y.tab.h"
using namespace std;

vector<string> stringlist;
int line_count=1;
int error_count=0;
extern YYSTYPE yylval;

%}

Letter [a-zA-Z]
Digit [0-9]
Digits [0-9]+
PP [+]{2}
MM -{2}
L <
LE <=
G >
GE >=
EE ==
NE !=
Assign =
And &&
Or [|]{2}
Not !
LParen [(]{1}
RParen [)]{1}
LCurl [{]{1}
RCurl [}]{1}
LThird [[]{1}
RThird []]{1}
Comma ,
Semicolon ;
NL2 \r
NL [NL2]?\n
WS [ \t\v]+
Alpha [a-zA-Z_]+
Alphanumeric [a-zA-Z0-9]
Identifier {Alpha}[a-zA-Z0-9]*
SingleQuote '
ForwardSlash "//"
FSlash //
MultiLineComment "/*"
MultiLineCommentEnd "*/"

EmptyChar '' 
BackSlash \\
BackSlashChar ^'\\\\'$



AnyChar [`~!@#$%&*-_=+|":;?/>.<,^{LParen}{RParen}{LThird}{RThird}{LCurl}{RCurl}{SingleQuote}a-zA-Z0-9]
Char {AnyChar}*



DoubleBackSlash \\\\
InvalidNum [0-9]+[a-zA-DF-Z]+([0-9]+)?

InvertedQuote ["]
Dot [.]{1}


%%

if { 
      SymbolInfo *s= new SymbolInfo(yytext,"IF");
      yylval = (YYSTYPE)s;
      return IF;}
else { SymbolInfo *s= new SymbolInfo(yytext,"ELSE");
      yylval = (YYSTYPE)s;return ELSE;}
for { SymbolInfo *s= new SymbolInfo(yytext,"FOR");
      yylval = (YYSTYPE)s;return FOR;}
while {SymbolInfo *s= new SymbolInfo(yytext,"WHILE");
      yylval = (YYSTYPE)s;return WHILE;}
do { SymbolInfo *s= new SymbolInfo(yytext,"DO");
      yylval = (YYSTYPE)s;return DO;}
break { SymbolInfo *s= new SymbolInfo(yytext,"BREAK");
      yylval = (YYSTYPE)s;return BREAK;}
int { SymbolInfo *s= new SymbolInfo(yytext,"INT"); stringlist.push_back(s->getName());
      yylval = (YYSTYPE)s;return INT;}
char { SymbolInfo *s= new SymbolInfo(yytext,"CHAR");
      yylval = (YYSTYPE)s;return CHAR;}
float {SymbolInfo *s= new SymbolInfo(yytext,"FLOAT");
      yylval = (YYSTYPE)s;return FLOAT;}
double {SymbolInfo *s= new SymbolInfo(yytext,"DOUBLE");
      yylval = (YYSTYPE)s;return DOUBLE;}
void {SymbolInfo *s= new SymbolInfo(yytext,"VOID");
      yylval = (YYSTYPE)s;return VOID;}
return { SymbolInfo *s= new SymbolInfo(yytext,"RETURN");
      yylval = (YYSTYPE)s;return RETURN;}
switch {SymbolInfo *s= new SymbolInfo(yytext,"SWITCH");
      yylval = (YYSTYPE)s;return SWITCH;}
case { SymbolInfo *s= new SymbolInfo(yytext,"CASE");
      yylval = (YYSTYPE)s;return CASE;} 
default { SymbolInfo *s= new SymbolInfo(yytext,"DEFAULT");
      yylval = (YYSTYPE)s;return DEFAULT;}
continue {SymbolInfo *s= new SymbolInfo(yytext,"CONTINUE");
      yylval = (YYSTYPE)s;return CONTINUE;}
println {return PRINTLN;}




{Digits} {
	SymbolInfo *s= new SymbolInfo(yytext,"CONST_INT");
	s->intValue = atoi(yytext);
	s->dataType = "int";
	yylval = (YYSTYPE)s;
	//cout<<"found int at line "<<line_count<<" ja holo "<<yytext<<endl;
	return CONST_INT;}
{Digit}*(\.{Digit}+)?(E[+-]?{Digit}+)? {
	SymbolInfo *s= new SymbolInfo(yytext,"CONST_FLOAT");
	//printf("const float---1 pailam line %d te ja holo %s\n",line_count,yytext);
	s->floatValue = atof(yytext);
	s->dataType = "float";
	yylval = (YYSTYPE)s;
  	return CONST_FLOAT; }






[+-] { SymbolInfo *s= new SymbolInfo(yytext,"ADDOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s;return ADDOP; }
[*/%] { SymbolInfo *s= new SymbolInfo(yytext,"MULOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return MULOP;}
{MM} { SymbolInfo *s= new SymbolInfo(yytext,"DECOP"); yylval = (YYSTYPE)s;return DECOP;}
{PP} { SymbolInfo *s= new SymbolInfo(yytext,"INCOP"); yylval = (YYSTYPE)s; return INCOP;}

{L} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP;}
{LE} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP; }
{G} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP;}
{GE} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP; }
{EE} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP;}
{NE} { SymbolInfo *s= new SymbolInfo(yytext,"RELOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return RELOP;}
{Assign} { SymbolInfo *s= new SymbolInfo(yytext,"ASSIGNOP"); yylval = (YYSTYPE)s; return ASSIGNOP;}
{And} { SymbolInfo *s= new SymbolInfo(yytext,"LOGICOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return LOGICOP;}
{Or} { SymbolInfo *s= new SymbolInfo(yytext,"LOGICOP");stringlist.push_back(s->getName()); yylval = (YYSTYPE)s; return LOGICOP;}

{Not} {SymbolInfo *s= new SymbolInfo(yytext,"NOT"); yylval = (YYSTYPE)s; return NOT;}
{Comma} { SymbolInfo *s= new SymbolInfo(yytext,"COMMA"); yylval = (YYSTYPE)s; return COMMA;} 
{Semicolon} { SymbolInfo *s= new SymbolInfo(yytext,"SEMICOLON"); yylval = (YYSTYPE)s; return SEMICOLON;}
{LParen} {SymbolInfo *s= new SymbolInfo(yytext,"LPAREN"); yylval = (YYSTYPE)s; return LPAREN; }
{RParen} { SymbolInfo *s= new SymbolInfo(yytext,"RPAREN"); yylval = (YYSTYPE)s; return RPAREN;}

{LCurl}  { SymbolInfo *s= new SymbolInfo(yytext,"LCURL"); yylval = (YYSTYPE)s; return LCURL;}
{RCurl}  { SymbolInfo *s= new SymbolInfo(yytext,"RCURL"); yylval = (YYSTYPE)s; return RCURL;}
{LThird} { SymbolInfo *s= new SymbolInfo(yytext,"LTHIRD"); yylval = (YYSTYPE)s; return LTHIRD;}
{RThird} { SymbolInfo *s= new SymbolInfo(yytext,"RTHIRD"); yylval = (YYSTYPE)s; return RTHIRD;}




{NL} {line_count++; }
{WS} {}


{Identifier} {SymbolInfo *s= new SymbolInfo(yytext,"ID");
      yylval = (YYSTYPE)s;return ID;}


%%

int yywrap(void)
{
	return 1;
}

//{Digits}(.{Digits})(E[+-]?{Digits})?

/*


{InvalidNum} { PrintErrorNum(3,yytext);}
//{Digits}({Alpha}*)?{Dot}({Digits}*)?({Alpha}*)?{Dot}({Digits}*)?({Alpha}*)? { PrintErrorNum(1,yytext);  }
{Digits}(.{Digits})?E[+-]?({Digit}*){Dot}({Digits}*)?({Alpha}*)? { PrintErrorNum(2,yytext); }

*/
//{Digits}{Dot} { /*ConvertDotToInt();*/}

//newst {Digits}{Dot}{Digits}
