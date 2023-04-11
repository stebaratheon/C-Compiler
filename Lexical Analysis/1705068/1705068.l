%option noyywrap

%x STRING_STATE
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_STUFF

%{
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<cstring>
#include"1705068.cpp"

SymbolTable st(7);

int word_count=0;
int line_count=1;
int const_char_count=0;
int back_slash=0;
int error_count=0;
int length=0;
string s1,s2;
char prevChar;
int flag=0;

void IncWc(){
	word_count++;
}

void ConstCharHandle(int state){	
	return ;
}

void Push(string name,string type){
	st.Insert(name,type);
	st.printAllScopeIf();
}

void Print(string token,string lexeme){
	st.PrintLog(line_count,token,lexeme);
}
void Final(){
	st.printAllScope();
	PrintFinal(line_count,error_count);
}
void PushSingleQuote(){
	st.Insert("'","CONST_CHAR");
	st.printAllScopeIf();
}
void PrintErrorStr(int num,string err)
{
	error_count++;
	ErrorPrint(line_count,num,err);
}
void PrintErrorNum(int num,char *cp)
{
	error_count++;
	s2="";
	int n= strlen(cp);
	for(int i=0;i<n;i++) s2+=cp[i];
	ErrorPrint(line_count,num,s2);
}
void PrintErrorChar(int num,char *cp)
{
	error_count++;
	s2="";
	int n= strlen(cp);
	for(int i=0;i<n;i++) s2+=cp[i];
	ErrorPrint(line_count,num,s2);
}
void PushNewLine(){
	s1="";
	s1+=10;
	st.Insert(s1,"CONST_CHAR");
	st.printAllScopeIf();
}
void EnterScope(){
	st.EnterScope(7);
}
void ExitScope(){
	st.ExitScope();
}
void PrintPushConstChar(){
	if(strlen(yytext)==2)
	{
		PrintErrorChar(6,yytext); return ;
	}	
	if(strlen(yytext)>4){
		PrintErrorChar(4,yytext);
	        return ;	
	}
	if(strlen(yytext)==4)
	{
		if(yytext[1]!=92)
		{
			PrintErrorChar(4,yytext); return ;
		}
	}
	if(strlen(yytext)==3 && yytext[1]==92)
	{
		PrintErrorChar(5,yytext); return ;
	}
	s1 = "";
	char c=yytext[1];
	s1+=yytext[0]; s1+=yytext[1]; s1+=yytext[2];
	if(strlen(yytext)==4) s1+=yytext[3];	
	st.Insert(s1,"CONST_CHAR");
	st.printAllScopeIf();	
	fprintf(yyout,"< CHAR_CONST, %s",yytext);
	st.PrintLog(line_count,"CONST_CHAR",s1);
}
void PrintPushBackSlash(){
	string temp="";
	temp+=92;
	st.PrintLog(line_count,"CONST_CHAR",temp);
	st.Insert(temp,"CHAR_CONST");
}
void StringInit(){
	s1 = ""; s2="";
	s1+='"'; s2+= '"';
	prevChar = '\0';
}
void HandleString(){
	if( (yytext[0]==13  || yytext[0]==10) && (prevChar!=92 || prevChar==0) )
	{
		line_count++;
		PrintErrorStr(7,s1);
		BEGIN 0;
		return ;
	}
	if( (yytext[0]==13  || yytext[0]==10) && prevChar==92  )
	{
		line_count++;
		s1+=yytext[0];
	}
	if(prevChar!='\\')
	{
		if(yytext[0]!=92)
			{s1+=yytext[0]; s2+=yytext[0];}
	}
	else if(prevChar!=92){
		if(yytext[0]=='n'){
			PrintErrorStr(7,s1);
			BEGIN 0;
			return ;		
		}	
	}
	if(prevChar=='\\')
	{
		if(yytext[0]=='n') s1+=10;
		if(yytext[0]=='t') {s1+=9; s2+=9;}
	}
	//printf("string state running with character %c ascii code %d\n",yytext[0],yytext[0]);
	prevChar = yytext[0];
}
void HandleStringFinal(){
	//printf("string final state running with character %c ascii code %d\n",yytext[0],yytext[0]);
	if(prevChar!=92)
	{
		s1+='"'; s2+='"';
		PrintString(line_count,"STRING",s1,s2);
		//convert string to char array to print in tokens.txt
		int n=s2.length();
		char ara[n+1];
		strcpy(ara, s2.c_str());
		fprintf(yyout,"<STRING, %s>",ara);		
		BEGIN 0;
		return ;
	}	
	prevChar = yytext[0];
}
void HandleStringNewLine(){
	if(prevChar!=92){
		//printf("string new error diye out\n");
		PrintErrorStr(7,s1);
		BEGIN 0;
		return ;
	}
	prevChar=yytext[0];
}
void HandleStringDBS(){
	s1+=92;
	prevChar = '\0';
}
void InitSingleLineComment(){
	prevChar ='\0';
	s1="";
	s1+='/';
	s1+='/';
}
void HandleSingleLineComemnt(){
	if(yytext[0]==10 || yytext[0]==13)
	{
		if(prevChar!='\\'){
			Print("COMMENT",s1);
			BEGIN 0;
			return ;		
		}
	}
	if((yytext[0]==10 || yytext[0]==13) && prevChar!='\\'){
		line_count++;	
	}
	s1+=yytext[0];
	prevChar = yytext[0];
}
void HandleMultiLineStart(){
	s1="";
	s1+='/'; s1+='*';
}
void HandleMultiLine(){
	s1+=yytext[0];
	if(yytext[0]==10 || yytext[0]==13)
	{
		line_count++;
	}
}
void HandleMultiLineEnd(){
	s1+='*'; s1+='/';
	Print("MULTI_LINE_COMMENT",s1);
	BEGIN 0;
}
void HandleMultiLineUnfinished()
{
	PrintErrorStr(8,s1);
	BEGIN 0;	
}
void ConvertDotToInt()
{
	s1="";
	int n=strlen(yytext);
	for(int i=0;i<n-1;i++) s1+=yytext[i];
	Print("CONST_INT",s1);
	Push(s1,"CONST_INT");
	//converting string s1 to a charatcer array
	n=s1.length();
	char ara[n+1];
	strcpy(ara, s1.c_str());
	fprintf(yyout,"<CONST_INT, %s>",ara);
}
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

















if { Print("IF","if"); fprintf(yyout,"<IF>");}
else { Print("ELSE","else");fprintf(yyout,"<ELSE>");}
for { Print("FOR","for");fprintf(yyout,"<FOR>");}
while {Print("WHILE","while");fprintf(yyout,"<WHILE>");}
do { Print("DO","do");fprintf(yyout,"<DO>");}
break { Print("BREAK","break");fprintf(yyout,"<BREAK>");}
int { Print("INT","int");fprintf(yyout,"<INT>");}
char { Print("CHAR","char");fprintf(yyout,"<CHAR>");}
float {Print("FLOAT","float");fprintf(yyout,"<FLOAT>");}
double {Print("DOUBLE","double");fprintf(yyout,"<DOUBLE>");}
void {Print("VOID","void");fprintf(yyout,"<VOID>");}
return {Print("RETURN","return");fprintf(yyout,"<RETURN>");}
switch {Print("SWITCH","switch");fprintf(yyout,"<SWITCH>");}
case {Print("CASE","case");fprintf(yyout,"<CASE>");} 
default {Print("DEFAULT","default");fprintf(yyout,"<DEFAULT>");}
continue {Print("CONTINUE","continue");fprintf(yyout,"<CONTINUE>");}




{Digits}{Dot} {ConvertDotToInt();}
{Digits}{Dot}E{Digits} {Print("CONST_FLOAT",yytext); Push(yytext,"CONST_FLOAT"); fprintf(yyout,"<CONST_FLOAT, %s>",yytext);}
{Digits} { Print("CONST_INT",yytext); Push(yytext,"CONST_INT"); fprintf(yyout,"<CONST_INT, %s>",yytext);}
{Digits}(.{Digits})?(E[+-]?{Digits})?  {Print("CONST_FLOAT",yytext); Push(yytext,"CONST_FLOAT"); fprintf(yyout,"<CONST_FLOAT, %s>",yytext);}


{InvalidNum} {PrintErrorNum(3,yytext);}
{Digits}({Alpha}*)?{Dot}({Digits}*)?({Alpha}*)?{Dot}({Digits}*)?({Alpha}*)? {PrintErrorNum(1,yytext);}
{Digits}(.{Digits})?E[+-]?({Digit}*){Dot}({Digits}*)?({Alpha}*)? {PrintErrorNum(2,yytext);}





[+-] {Print("ADDOP",yytext); fprintf(yyout,"<ADDOP, %s>",yytext);}
[*/%] {Print("MULOP",yytext); fprintf(yyout,"<MULOP, %s>",yytext);}
{MM} {Print("INCOP",yytext); fprintf(yyout,"<INCOP, %s>",yytext);}
{PP} {Print("PP",yytext); fprintf(yyout,"<INCOP, %s>",yytext);}

{L} {Print("RELOP",yytext); fprintf(yyout,"<RELOP, %s>",yytext);}
{LE} {Print("RELOP",yytext);fprintf(yyout,"<RELOP, %s>",yytext);}
{G} {Print("RELOP",yytext); fprintf(yyout,"<RELOP, %s>",yytext);}
{GE} {Print("RELOP",yytext);fprintf(yyout,"<RELOP, %s>",yytext);}
{EE} {Print("RELOP",yytext);fprintf(yyout,"<RELOP, %s>",yytext);}
{NE} {Print("RELOP",yytext);fprintf(yyout,"<RELOP, %s>",yytext);}
{Assign} {Print("ASSIGNOP",yytext); fprintf(yyout,"<ASSIGNOP, %s>",yytext);}
{And} {Print("LOGICOP",yytext);fprintf(yyout,"<LOGICOP, %s>",yytext);}
{Or} {Print("LOGICOP",yytext);fprintf(yyout,"<LOGICOP, %s>",yytext);}

{Not} {Print("NOT",yytext);fprintf(yyout,"<NOT, %s>",yytext);}
{Comma} {Print("COMMA",yytext);fprintf(yyout,"<COMMA, %s>",yytext);} 
{Semicolon} {Print("SEMICOLON",yytext);fprintf(yyout,"<SEMICOLON, %s>",yytext);}
{LParen} {Print("LPAREN",yytext);fprintf(yyout,"<LPAREN, %s>",yytext); }
{RParen} {Print("RPAREN",yytext);fprintf(yyout,"<RPAREN, %s>",yytext);}

{LCurl}  {Print("LCURL",yytext);EnterScope();fprintf(yyout,"<LCURL, %s>",yytext);}
{RCurl}  {Print("RCURL",yytext); ExitScope();fprintf(yyout,"<RCURL, %s>",yytext);}
{LThird} {Print("LTHIRD",yytext);fprintf(yyout,"<LTHIRD, %s>",yytext);}
{RThird} {Print("RTHIRD",yytext);fprintf(yyout,"<LTHIRD, %s>",yytext);}




{NL} {line_count++;}
{WS} {}


{Identifier} {Print("ID",yytext); Push(yytext,"ID");fprintf(yyout,"<ID, %s>",yytext);}




'{Char}{WS}+{Char}?' {PrintErrorChar(4,yytext);}
'{Char} {PrintErrorChar(5,yytext);}
'{Char}' {PrintPushConstChar(); }









{InvertedQuote} { BEGIN STRING_STATE;
		  StringInit();
		  length++;
		}
<STRING_STATE>{InvertedQuote} { length++;
				HandleStringFinal();
		}
<STRING_STATE>{DoubleBackSlash} { length++; 
				HandleStringDBS();
		}
<STRING_STATE>. { length++; HandleString();}


{ForwardSlash} {
		BEGIN SINGLE_LINE_COMMENT;
		InitSingleLineComment();}

<SINGLE_LINE_COMMENT>. {HandleSingleLineComemnt();}

{MultiLineComment} {HandleMultiLineStart();BEGIN MULTI_LINE_STUFF;}
<MULTI_LINE_STUFF>{MultiLineCommentEnd} {HandleMultiLineEnd();}
<MULTI_LINE_STUFF>. {HandleMultiLine();}
<MULTI_LINE_STUFF><<EOF>> {HandleMultiLineUnfinished();}


<<EOF>> {Final(); return 0;}
[`~#$] {PrintErrorChar(9,yytext);}
. {}
%%














int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	FILE *fop=fopen("1705068_token.txt","w");
	if(fop==NULL){
		printf("Cannot open specified token file\n");
		return 0;
	}
	

	yyin= fin;
	yyout = fop;
	file.open("1705068_log.txt");
	yylex();
	fclose(yyin);
	fclose(yyout);
	return 0;
}
