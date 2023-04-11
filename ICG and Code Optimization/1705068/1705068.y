%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "symbolinfo.h"
#include "symboltable.h"
using namespace std;
#define YYSTYPE SymbolInfo*    /* yyparse() stack type */

int yylex(void);
int yyparse(void);


FILE *fp,*fp2,*fp3,*fp4;
ofstream filelog,fileerror;

string dataType;
vector<string> paramName;
vector<string> paramName2;
vector<string> paramType;
vector<string> paramType2;
int paramIndex=0;
int numOfParameters=0;
int bucketSize = 30;
int indic=0;
int func=0;
SymbolTable *symbolTable = new SymbolTable(31);
SymbolInfo* emptySymbol = new SymbolInfo(); 

//icg 
string dataCode,stmtCode,paramCode="";
string initCode = ".MODEL SMALL \n.STACK 100H \n.DATA\n\n";
string mainCode = ".CODE \n\n MAIN PROC \n\nMOV AX,@DATA \nMOV DS,AX \n\n";
string endCode = ""; 
int label_count=0,temp_count=0;
void AssemCodeLogicOp(SymbolInfo *s,string v1,string opcode,string v2);
string LabelGenerator();
string to_String(int a);
string newTempVar();
int para=0;

extern FILE *yyin;
extern int line_count;
extern int error_count;


void yyerror(string s){
	fprintf(fp3,"Error at line %d: %s\n\n",line_count,s.c_str());
	fprintf(fp4,"Error at line %d: %s\n\n",line_count,s.c_str());
}

void WarningMsg(string s){
	fprintf(fp3,"Line %d: %s\n\n",line_count,s.c_str());
	//fileerror<<s<<" at line number = "<<line_count<<" "<<s<<"\n"<<endl;
	//filelog<<s<<" at line number = "<<line_count<<" "<<s<<"\n"<<endl;
}
string ExtractDataType(string symbolName)
{
	string dumb="";
	SymbolInfo* ts1=NULL;
	ts1 = symbolTable->Lookup(symbolName);
	if(ts1!=NULL)
	{
		//cout<<"ffff found data type = "<<ts1->dataType<<endl;
		return ts1->dataType;
	}
	return dumb;
}
bool ParametersVerify(SymbolInfo *exst)
{
	int nop = paramType2.size();
	if(exst->parameters != nop)
	{
		yyerror("Total number of arguments mismatch with declaration in function "+exst->name);
		error_count++; 
		paramType2.clear();paramName2.clear();
		return false;
	}
	else
	{	
		int sz= exst->paramName.size();
		for(int i=0;i<sz;i++)
		{
			if(exst->paramType[i] != paramType2[i])
			{
				char st[10]; sprintf(st, "%d", i+1); string ns(st);				
				yyerror(ns+"th argument mismatch in function "+exst->name);
				error_count++;
				paramType2.clear();paramName2.clear();
				return false;
			}
		}
		paramType2.clear();paramName2.clear();
		return true;
	}
}
bool ParametersVerify(SymbolInfo *exst,SymbolInfo *nw)
{
	if(exst->parameters != nw->parameters)
	{
		yyerror("Total number of arguments mismatch with declaration in function "+exst->name);
		error_count++;
		return false;
	}
	else
	{	
		int sz= exst->paramName.size();
		for(int i=0;i<sz;i++)
		{
			if(exst->paramType[i] != nw->paramType[i])
			{
				//yyerror("Type of parameters does not match in function "+exst->name);
				char st[10]; sprintf(st, "%d", i+1); string ns(st);				
				yyerror(ns+"th argument mismatch in function "+exst->name);				
				error_count++; paramType.clear(); paramName.clear();
				return false;
			}
		}
		paramType.clear();
		paramName.clear();
		return true;
	}
}
void GlobalScopeInsertFunc(SymbolInfo* s,int funcIndicator)
{
	SymbolInfo *t=NULL;
	t = symbolTable->LookupGlobalScope(s);
	if(t!=NULL && funcIndicator==0)
	{
		yyerror("Multiple decalration of variable "+s->name);
		error_count++;
		return ;
	}
	if(t!=NULL && funcIndicator==1)
	{	
		if(t->isFunction==false)
		{
			yyerror("Multiple declaration of "+t->name);
			error_count++; return ;
		}		
		else
		{
			bool status = ParametersVerify(t,s);
			if(status==false)
				return ;
		}
	} 
	//s->dataType=dataType;
	bool status= symbolTable->InsertGlobal(s);
	if(status) { /*cout<<"xxfunction "<<s->name<<" inserted successfully and parameter dataType "<<s->dataType<<endl;*/ } 
	else
	{
		if(t->dataType!=s->dataType)
		{
			yyerror("Return type mismatch with function declaration in function "+t->name);
			error_count++;
			return ;
		}
	}
}
void InsertIdentifier(SymbolInfo* si)
{
	//cout<<"insert id called with name = "<<si->name<<" dataype = "<<dataType<<" array = "<<si->arraySize<<endl;
	SymbolInfo *temp = symbolTable->LookupCurrentScopeByName(si);
	bool status = false;	
	if(dataType=="void")
	{
		yyerror("Variable type cannot be void");
		error_count++; return ;
	}
	if(temp!=NULL)
	{	
		yyerror("Multiple declaration of "+si->name);
		error_count++;
		return ;
	}
	si->dataType = dataType;
	si->isFunction = false;
	//icg	
	dataCode += si->name+" DW ?\n";
	status = symbolTable->Insert(si);
}

void ArrayValidate(SymbolInfo* ara,SymbolInfo *size)
{
	//cout<<"insert array called with name = "<<ara->name<<" dataype = "<<dataType<<" array = "<<size->intValue<<endl;
	SymbolInfo *temp = symbolTable->LookupCurrentScope(ara,dataType);
	SymbolInfo *temp2 = symbolTable->LookupCurrentScopeByName(ara->name);	
	bool status;	
	if(temp!=NULL)
	{
		yyerror("Multiple declaration of array "+ara->name);
		error_count++;
		return ;
	}
	 if(size->dataType!="int")
	{
		yyerror("Array size must be integer");
		error_count++;
		return ;
	}
	if(size->intValue <1)
	{	
		yyerror("Array size must be at least 1");
		error_count++;
		return ;
	}
	if(temp2!=NULL)
	{
		yyerror("Multiple declaration of "+ara->name);
		error_count++; return ;
	}
	ara->arraySize = size->intValue;
	ara->dataType = dataType;
	status = symbolTable->Insert(ara);
	if(status)
	{
		ara->constructArray(); //cout<<"array "<<ara->name<<" inserted wiht size = "<<ara->arraySize<<endl;
		
		//icg
		string arraycode = "";
		arraycode += ara->name+" DW ";
		arraycode +=  to_String(size->intValue)+" DUP (?)\n";
		dataCode+=arraycode;	
	}
	else{
		//cout<<"array not inserted"<<endl;
	}
}
void CodeAssign(SymbolInfo *s,string s1,string s2)
{
	s->tempName = s1;
	string Code = "";
	Code += "MOV AX,"+s2+"\n";
	Code += "MOV "+s1+", AX \n";
	s->code += Code;
	return ;
}
void VariableAssign(SymbolInfo* s1,SymbolInfo* s2)
{
	//cout<<"variable assign called with value 11111 "<<s1->name<<" and "<<s1->dataType<<"-------line = "<<line_count<<endl;
	SymbolInfo* ts1,*ts2; //s1 is in the symbol table but s2 is not
	ts1=ts2=NULL;
	ts1 = symbolTable->Lookup(s1->name);
	ts2 = symbolTable->Lookup(s2->name);
	if(ts1!=NULL && ts2!=NULL)
	{    
		s1=ts1; s2= ts2;
	}
	if(ts1==NULL)//cout<<"ts1 is not null:: namae = "<<ts1->name<<" and array size of ts1 "<<ts1->arraySize<<endl;
	{
		yyerror("Undeclared variable "+s1->name);
		error_count++;
		return ;
	} 
	if(ts1->arraySize >0 && s2->arraySize>0 && (ts1->name!=s2->name ))
	{
		yyerror("Type mismatch. "+ts1->name+" is an array.");
		error_count++;
		return ;
	}
	if(s2->dataType=="float" && ts1->dataType!="float")
	{
		WarningMsg("Converting float into non float");
	}
	if(ts1->dataType=="int" && s2->dataType=="float")
	{ 	//cout<<"fffffffffffffffor this "<<endl;
		yyerror("Type mismatch");
		error_count++;
		return ;	
	}
	if(ts1->dataType=="int" && s2->dataType=="int") { ts1->intValue = s2->intValue; }
	if(ts1->dataType=="int" && s2->dataType=="char") { ts1->intValue = s2->charValue; }
	if(ts1->dataType=="float" && s2->dataType=="int") { ts1->floatValue = s2->intValue; }
	if(ts1->dataType=="float" && s2->dataType=="float") { ts1->floatValue = s2->floatValue; }
	if(ts1->dataType=="float" && s2->dataType=="char") { ts1->floatValue = s2->charValue; }
	if(ts1->dataType=="char" && s2->dataType=="int") { ts1->charValue = s2->intValue; }
	if(ts1->dataType=="char" && s2->dataType=="float") { ts1->charValue = s2->floatValue; }
	if(ts1->dataType=="char" && s2->dataType=="char") { ts1->charValue = s2->charValue; }
	
	if(s1->index==-1)// not array
	{
		CodeAssign(s1,s1->tempName,s2->tempName);
	}
	else
	{	
		ts1->code+= s2->code+s1->code;
		ts1->code += "LEA DI, "+s1->name+"\n";
		ts1->code += "MOV AX, "+s2->name+"\n";
		ts1->code += "ADD DI, "+to_string(s1->index)+"\n";
		ts1->code += "MOV [DI], AX\n";
		ts1->tempName = newTempVar();  
	}

	//actually returning s1 from this function
	s1 = ts1;
}

SymbolInfo* GetArrayElement(SymbolInfo* s1,SymbolInfo *s2)
{
	SymbolInfo* temp = NULL;
	int idx = s2->intValue;
	temp = symbolTable->Lookup(s1->name); 
	if(temp==NULL)
	{
		yyerror("Array "+s1->name+" is not declared in this scope");
		error_count++;
		return temp;
	}
	else if(s2->dataType!="int")
	{
		yyerror("Expression inside third brackets not an integer ie, Array index must be integer");
		error_count++;
		return temp;
	}
	else if(temp->arraySize==-1)
	{
		yyerror(s1->name+" is not an array");
		error_count++;
		return temp;
	}
	else if(idx>=temp->arraySize || idx<0)
	{
		yyerror("Invalid array index");
		error_count++;
		return temp;
	}
	return temp->getArrayElement(idx);
}
SymbolInfo* GetIdentifier(SymbolInfo* s,SymbolInfo* ss)
{
	SymbolInfo* key=NULL;
	key = symbolTable->Lookup(s->name);// if(key==NULL) cout<<"pp "<<s->name<<" is not found"<<endl;else {cout<<"pp "<<s->name<<" is  found"<<endl;}
	if(key!=NULL)
	{
		ss->dataType = key->dataType; ss->type=key->type;
		ss->intValue = key->intValue;
		ss->floatValue = key->floatValue;
		ss->charValue = key->charValue;
		ss->name = key->name;
		
		ss->arraySize = key->arraySize; ss->parameters= key->parameters; ss->isFunction = key->isFunction;
		ss->nextSymbol = key->nextSymbol; ss->Array = key->Array;
		ss->paramType = key->paramType; ss->paramName = key->paramName;
		return key;
	}
	else
	{
		return emptySymbol;
	}
}

void AssemCodeAddop(SymbolInfo *s,string v1,string v2,int signBit)
{
	string temp = newTempVar();
	s->tempName = temp;       
	string Code = "";
	Code += "MOV AX, "+v1+"\n";
	if(signBit==0)// plus
	{
		Code += "ADD AX, "+v2+"\n";
	}
	else 
	{
		Code += "SUB AX, "+v2+"\n";
	}
	Code += "MOV "+temp+" ,AX \n";
	s->code += Code;
}

void AddSymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{
	SymbolInfo *oprnd1,*oprnd2;
	oprnd1=oprnd2=NULL;
	// 2 operand k check kortesi symboltable e ase kina, for debugging purpose
	oprnd1 = symbolTable->Lookup(s1->name);
	oprnd2 = symbolTable->Lookup(s3->name);
	if( s1->dataType=="int" &&  s3->dataType=="int"  )
	{
		s4->dataType = "int";
	}
	else s4->dataType="float";
	if(s2->name=="+")
	{
		if(s1->dataType=="int" && s3->dataType=="int") s4->intValue = s1->intValue + s3->intValue;
		else if(s1->dataType=="int" && s3->dataType=="float") s4->floatValue = s1->intValue + s3->floatValue;
		else if(s1->dataType=="int" && s3->dataType=="char") s4->floatValue = s1->intValue + s3->charValue;

		else if(s1->dataType=="float" && s3->dataType=="int") s4->floatValue = s1->floatValue+s3->intValue;
		else if(s1->dataType=="float" && s3->dataType=="float") s4->floatValue = s1->floatValue + s3->floatValue;
		else if(s1->dataType=="float" && s3->dataType=="char") s4->floatValue = s1->floatValue + s3->charValue;

		else if(s1->dataType=="char" && s3->dataType=="int") s4->floatValue = s1->charValue+s3->intValue;
		else if(s1->dataType=="char" && s3->dataType=="float") s4->floatValue = s1->charValue + s3->floatValue;
		else if(s1->dataType=="char" && s3->dataType=="char") s4->floatValue = s1->charValue + s3->charValue;

		AssemCodeAddop(s4,s1->tempName,s3->tempName,0); 
	}
	else if(s2->name=="-")
	{
		if(s1->dataType=="int" && s3->dataType=="int") s4->intValue = s1->intValue - s3->intValue;
		else if(s1->dataType=="int" && s3->dataType=="float") s4->floatValue = s1->intValue - s3->floatValue;
		else if(s1->dataType=="int" && s3->dataType=="char") s4->intValue = s1->intValue - s3->charValue;

		else if(s1->dataType=="float" && s3->dataType=="int") s4->floatValue = s1->floatValue - s3->intValue;
		else if(s1->dataType=="float" && s3->dataType=="float") s4->floatValue = s1->floatValue - s3->floatValue;
		else if(s1->dataType=="float" && s3->dataType=="char") s4->floatValue = s1->floatValue - s3->charValue;

		else if(s1->dataType=="char" && s3->dataType=="int") s4->intValue = s1->charValue - s3->intValue;
		else if(s1->dataType=="char" && s3->dataType=="float") s4->floatValue = s1->charValue - s3->floatValue;
		else if(s1->dataType=="char" && s3->dataType=="char") s4->intValue = s1->charValue - s3->charValue;
		
		AssemCodeAddop(s4,s1->tempName,s3->tempName,1);
	}
}

void AssemCodeMod(SymbolInfo *s,string v1,string v2)
{
	string temp = newTempVar(); 
	s->tempName = temp;
	string var2 = newTempVar();
	string Code = "";
	Code+= "MOV "+var2+", "+ v2+" \n";
	Code += "MOV DX, 0\n";
	Code += "MOV AX, "+v1+" \n";
	Code += "DIV "+var2 +"\n";
	Code += "MOV "+temp +" ,DX\n";
	s->code += Code;
}

void AssemCodeMul(SymbolInfo *s,string v1,string v2,int signBit)
{
	string temp = newTempVar(); 
	s->tempName = temp;
	string Code = "";
	Code += "MOV DX, 0 \n";
	Code += "MOV AX, "+v1+" \n";
	if(signBit==0)
	{
		Code += "MUL "+v2+" \n";
	}
	else
	{
		Code += "DIV "+v2+" \n";
	}
	Code += "MOV "+temp+" ,AX \n";
	s->code += Code; 
}

void MultiplySymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{	
	SymbolInfo *oprnd1,*oprnd2;
	oprnd1=oprnd2=NULL;
	// 2 operand k check kortesi symboltable e ase kina, for debugging purpose
	oprnd1 = symbolTable->Lookup(s1->name);
	oprnd2 = symbolTable->Lookup(s3->name);
	if( !(s3->dataType=="int" && s1->dataType=="int") && s2->name=="%")
	{
		yyerror("Non-Integer operand on modulus operator");
		error_count++;
		return ;
	}
	// icg mod handled here
	if( !(s3->dataType!="int" || s1->dataType!="int") && s2->name=="%")
	{
		s4->dataType = "int";
		if(s3->intValue==0)
		{
			yyerror("Divide by zero exception");
			error_count++;
			return ;
		}
		s4->intValue = s1->intValue % s3->intValue;
		AssemCodeMod(s4,s1->tempName,s3->tempName);		
		return ;
	}
	if( s1->dataType=="int"  && s3->dataType=="int"  ) s4->dataType = "int";
	else s4->dataType = "float";
	if(s2->name=="*")
	{
		if(s1->dataType=="int" && s3->dataType=="int") { s4->intValue=s1->intValue * s3->intValue; }
		else if(s1->dataType=="int" && s3->dataType=="float") { s4->floatValue=s1->intValue * s3->floatValue; }
		else if(s1->dataType=="int" && s3->dataType=="char") { s4->intValue=s1->intValue * s3->charValue; }

		if(s1->dataType=="float" && s3->dataType=="int") { s4->floatValue=s1->floatValue * s3->intValue; }
		else if(s1->dataType=="float" && s3->dataType=="float") { s4->floatValue = s1->floatValue * s3->floatValue; }
		else if(s1->dataType=="float" && s3->dataType=="char") { s4->floatValue = s1->floatValue * s3->charValue; }

		if(s1->dataType=="char" && s3->dataType=="int") { s4->floatValue = s1->charValue * s3->intValue; }
		else if(s1->dataType=="char" && s3->dataType=="float") { s4->floatValue = s1->charValue * s3->floatValue; }
		else if(s1->dataType=="char" && s3->dataType=="char") { s4->floatValue = s1->charValue * s3->charValue; }
		AssemCodeMul(s4,s1->tempName,s3->tempName,0);
	}
	else if(s2->name=="/")
	{
		if(s1->dataType=="int" && s3->dataType=="int") { s4->intValue=s1->intValue / s3->intValue; }
		else if(s1->dataType=="int" && s3->dataType=="float") { s4->floatValue=s1->intValue / s3->floatValue; }
		else if(s1->dataType=="int" && s3->dataType=="char") { s4->intValue=s1->intValue / s3->charValue; }

		if(s1->dataType=="float" && s3->dataType=="int") { s4->floatValue=s1->floatValue / s3->intValue; }
		else if(s1->dataType=="float" && s3->dataType=="float") { s4->floatValue = s1->floatValue / s3->floatValue; }
		else if(s1->dataType=="float" && s3->dataType=="char") { s4->floatValue = s1->floatValue / s3->charValue; }

		if(s1->dataType=="char" && s3->dataType=="int") { s4->floatValue = s1->charValue / s3->intValue; }
		else if(s1->dataType=="char" && s3->dataType=="float") { s4->floatValue = s1->charValue / s3->floatValue; }
		else if(s1->dataType=="char" && s3->dataType=="char") { s4->floatValue = s1->charValue / s3->charValue; }
		AssemCodeMul(s4,s1->tempName,s3->tempName,1);
	}
	//cout<<"multiply ended with $$ intValue= "<<s4->intValue<<" and datatype "<<s4->dataType<<endl;
}
void LogicalOpSymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{
	s4->dataType="int";
	if(s1->dataType=="int" && s3->dataType=="int")
	{
		if(s2->name=="&&") s4->intValue = s1->intValue && s3->intValue;
		if(s2->name=="||") s4->intValue = s1->intValue || s3->intValue;
	}
	else if(s1->dataType=="int" && s3->dataType=="float")
	{
		if(s2->name=="&&") s4->intValue = s1->intValue && s3->floatValue;
		if(s2->name=="||") s4->intValue = s1->intValue || s3->floatValue;
	}
	else if(s1->dataType=="float" && s3->dataType=="int")
	{
		if(s2->name=="&&") s4->intValue = s1->floatValue && s3->intValue;
		if(s2->name=="||") s4->intValue = s1->floatValue || s3->intValue;
	}
	else if(s1->dataType=="float" && s3->dataType=="float")
	{
		if(s2->name=="&&") s4->intValue = s1->floatValue && s3->floatValue;
		if(s2->name=="||") s4->intValue = s1->floatValue || s3->floatValue;
	}	
	AssemCodeLogicOp(s4,s1->tempName,s2->name,s3->tempName);
	//cout<<"logical sheshe symbol  "<<s2->name<<" s1= "<<s1->intValue<<" s3= "<<s3->intValue<<" s4 = "<<s4->intValue<<endl;
}

void AssemCodeRelop(SymbolInfo *s,string v1,string opcode,string v2)
{
	string Code = "";
	string Label1= LabelGenerator();
	string Label2 = LabelGenerator();
	string tempVar = newTempVar();
	s->tempName = tempVar;//tempVar will hold the value of the comparison result
	
	Code += "MOV AX, "+v1+" \n";
	Code += "CMP AX, "+v2+" \n";
		
	if(opcode==">")
	{
		Code += "JG "+Label1+" \n";
	}
	else if(opcode ==">=")
	{
		Code += "JGE "+Label1+" \n";
	}
	else if(opcode == "<")
	{
		Code += "JL "+Label1+" \n";
	}
	else if(opcode =="<=")
	{
		Code += "JLE "+Label1+" \n";
	}
	else if(opcode=="==")
	{
		Code += "JE "+Label1+" \n";
	}
	else if(opcode =="!=")
	{
		Code += "JNE "+Label1+" \n";
	}
	Code += "MOV "+tempVar+", 0 \n";
	Code += "JMP "+Label2 +" \n";
	Code += Label1+": \n";
	Code += "MOV "+tempVar+", 1 \n";
	Code += Label2+": \n";
	s->code += Code;
}

void AssemCodeLogicOp(SymbolInfo *s,string v1,string opcode,string v2)
{
	string Code = "";
	string Label1= LabelGenerator();
	string Label2 = LabelGenerator();
	string tempVar = newTempVar();
	s->tempName = tempVar;//tempVar will hold the value of the comparison result
	
	if(opcode=="&&")
	{
		Code += "MOV AX, "+v1+" \n";
		Code += "CMP AX, 0 \n";
		Code += "JE "+Label2+" \n";
		Code += "MOV AX, "+v2+" \n";
		Code += "CMP AX, 0 \n";
		Code += "JE "+Label2+" \n";
		Code += "MOV "+tempVar+", 1 \n";
		Code += "JMP "+Label1+" \n";
		Code += Label2+": \n";
		Code += "MOV "+tempVar+", 0\n";
		Code += Label1+": \n"; 
	}
	else if(opcode=="||")
	{
		Code += "MOV AX, "+v1+" \n";
		Code += "CMP AX, 0 \n";
		Code += "JNE "+Label2+" \n";
		Code += "MOV AX, "+v2+" \n";
		Code += "CMP AX, 0 \n";
		Code += "JNE "+Label2+" \n";
		Code += "MOV "+tempVar+", 0 \n";
		Code += "JMP "+Label1+" \n";
		Code += Label2+": \n";
		Code += "MOV "+tempVar+", 1\n";
		Code += Label1+": \n";
	}
	s->code += Code;
}

void RelopSymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{
	//cout<<"relop called with symbol1 "<<s1->intValue<<" and symbol2 = "<<s3->intValue<<endl;
	s4->dataType="int";
	if(s1->dataType=="int" && s3->dataType=="int")
	{
		int a= s1->intValue, b= s3->intValue;int c=a;
		if(s2->name==">") s4->intValue = a>b;
		if(s2->name==">=") s4->intValue = a>=b;;
		if(s2->name=="<") {s4->intValue = (a<b);}
		if(s2->name=="<=") s4->intValue = a<=b;
		if(s2->name=="==") s4->intValue = a==b;
		if(s2->name=="!=") s4->intValue = a!=b;
	}
	else if(s1->dataType=="int" && s3->dataType=="float")
	{
		if(s2->name==">") s4->intValue = s1->intValue > s3->floatValue;
		if(s2->name==">=") s4->intValue = s1->intValue >= s3->floatValue;
		if(s2->name=="<") s4->intValue = s1->intValue < s3->floatValue;
		if(s2->name=="<=") s4->intValue = s1->intValue <= s3->floatValue;
		if(s2->name=="==") s4->intValue = s1->intValue == s3->floatValue;
		if(s2->name=="!=") s4->intValue = s1->intValue != s3->floatValue;
	}
	else if(s1->dataType=="float" && s3->dataType=="int")
	{
		if(s2->name==">") s4->intValue = s1->floatValue > s3->intValue;
		if(s2->name==">=") s4->intValue = s1->floatValue >= s3->intValue;
		if(s2->name=="<") s4->intValue = s1->floatValue < s3->intValue;
		if(s2->name=="<=") s4->intValue = s1->floatValue <= s3->intValue;
		if(s2->name=="==") s4->intValue = s1->floatValue == s3->intValue;
		if(s2->name=="!=") s4->intValue = s1->floatValue != s3->intValue;
	}
	else if(s1->dataType=="float" && s3->dataType=="float")
	{
		if(s2->name==">") s4->intValue = s1->floatValue > s3->floatValue;
		if(s2->name==">=") s4->intValue = s1->floatValue >= s3->floatValue;
		if(s2->name=="<") s4->intValue = s1->floatValue < s3->floatValue;
		if(s2->name=="<=") s4->intValue = s1->floatValue <= s3->floatValue;
		if(s2->name=="==") s4->intValue = s1->floatValue == s3->floatValue;
		if(s2->name=="!=") s4->intValue = s1->floatValue != s3->floatValue;
	}
	AssemCodeRelop(s4,s1->tempName,s2->name,s3->tempName);
	//s4->code += s3->code+ s1->code;
}
void UnaryExpr(SymbolInfo *s1,SymbolInfo *s2,SymbolInfo *ss)
{
	//cout<<"XXunary called with "<<s1->name<<" and "<<s2->name<<endl;
	//for icg
	string tempVar = newTempVar();
	string Label1 = LabelGenerator();
	string var = s2->tempName;
	string Code = "";

	ss->dataType = s2->dataType;
	if(s1->name=="+")
	{
		if(s2->dataType=="int") ss->intValue = s2->intValue;
		if(s2->dataType=="float") ss->floatValue = s2->floatValue;
		if(s2->dataType=="char") ss->charValue = s2->charValue;
	}
	else if(s1->name=="-")
	{
		if(s2->dataType=="int") ss->intValue = -s2->intValue;
		if(s2->dataType=="float") ss->floatValue = -s2->floatValue;
		if(s2->dataType=="char") ss->charValue = -s2->charValue;

		//icg --> temp will hold the negated value of s2's value(var is the tempName of s2) 
		Code += "MOV AX, "+var+" \n";
		Code += "NEG AX \n";
		Code += "MOV "+tempVar+", AX \n";
	}
	else if(s1->name=="!")
	{
		ss->dataType="int";
		if(s2->dataType=="int") ss->intValue = !s2->intValue;
		if(s2->dataType=="float") ss->intValue = !s2->floatValue;
		if(s2->dataType=="char") ss->intValue = !s2->charValue;
		
		//icg --> temp will hold the value of var ie s2's value if it is 0, otherwise it will hold 1
		Code += "MOV AX, "+var+" \n";
		Code += "CMP AX, 0 \n";
		Code += "JE "+Label1+" \n";
		Code += "MOV AX, 1 \n";
		Code += Label1+": \n";
		Code += "MOV "+var+", AX \n";		
	}
	ss->code += Code;
}
void PseudoAssign(SymbolInfo* s,SymbolInfo* ss)
{
	//cout<<"Pseudo assign called with "<<s->name<<endl;
	ss->dataType = s->dataType;
	ss->name = s->name; ss->type=s->type;
	ss->intValue = s->intValue; ss->floatValue= s->floatValue; ss->charValue = s->charValue;
	ss->arraySize = s->arraySize; ss->parameters= s->parameters; ss->isFunction = s->isFunction;
	ss->nextSymbol = s->nextSymbol; ss->Array = s->Array;
	ss->paramType = s->paramType; ss->paramName = s->paramName;
	ss->tempName = s->tempName; ss->index = s->index; ss->code = s->code;
}
SymbolInfo* GetFunctionPtr(SymbolInfo *s)
{
	SymbolInfo *temp=NULL;
	temp = symbolTable->LookupGlobalScope(s);
	if(temp==NULL)
	{
		if(s->name=="printf" && paramName2.size()!=0)
		{
			int last=paramName2.size();last--; 
			SymbolInfo *temp2 = symbolTable->LookupCurrentScopeByName(paramName2[last]);
			if(temp2==NULL)
			{	
				yyerror("Undeclared variable "+paramName2[last]);
				error_count++;
			}
			paramName2.clear();
			paramType2.clear();
			return temp;
		}
		if(s->name!="printf"){
		yyerror("Undeclared function "+s->name); paramType2.clear();
		error_count++;
		return temp;}
	}
	if(temp!=NULL && temp->isFunction==false)
	{
		yyerror(s->name+" is not a function.");
		error_count++;
		return temp;
	}
	return temp;
}

//will be handled from the rul directly instead of writing another function
void AssemCodeIncOp(SymbolInfo *s,string var,int signBit)
{
	string temp = newTempVar();
	s->tempName = temp;
	string Code = "";
	Code += "MOV AX, "+var+" \n";
	Code += "MOV "+temp+", AX \n";
	if(signBit==0) Code += "INC AX \n";
	else Code += "DEC AX \n";
	Code += "MOV "+var+", AX \n";
	s->code += Code;
}

void IncOpSymbol(SymbolInfo *ss, SymbolInfo *s1)
{
	SymbolInfo *temp = symbolTable->LookupCurrentScopeByName(s1);
	if(temp!=NULL)
	{
		if(temp->dataType=="int") ss->intValue = temp->intValue+1;
		if(temp->dataType=="float") ss->floatValue = temp->floatValue+1;
		if(temp->dataType=="char") ss->charValue = temp->charValue+1; 
	}
	else
	{
		if(s1->dataType=="int") ss->intValue = s1->intValue+1;
		if(s1->dataType=="float") ss->floatValue = s1->floatValue+1;
		if(s1->dataType=="char") ss->charValue = s1->charValue+1;
	}
	AssemCodeIncOp(ss,s1->tempName,0);
}


void DecOpSymbol(SymbolInfo *ss, SymbolInfo *s1)
{
	SymbolInfo *temp = symbolTable->LookupCurrentScopeByName(s1);
	if(temp!=NULL)
	{
		if(temp->dataType=="int") ss->intValue = temp->intValue-1;
		if(temp->dataType=="float") ss->floatValue = temp->floatValue-1;
		if(temp->dataType=="char") ss->charValue = temp->charValue-1; 
	}
	else
	{
		if(s1->dataType=="int") ss->intValue = s1->intValue-1;
		if(s1->dataType=="float") ss->floatValue = s1->floatValue-1;
		if(s1->dataType=="char") ss->charValue = s1->charValue-1;
	}
	AssemCodeIncOp(ss,s1->tempName,1);
}

//icg brancing functions
void AssemCodePrintln(SymbolInfo *s,SymbolInfo *ss)
{	
	SymbolInfo *temp = symbolTable->LookupCurrentScopeByName(s);
	string Code = "";
	if(temp!=NULL){
		if(temp->dataType=="int")
		{
			string var = s->tempName;
			Code += "MOV AX, "+var+"\n";
			Code += "CALL PRINT \n";	
			Code += "MOV AH,2\n";
			Code += "MOV DL, 0DH \n";
			Code += "INT 21H \n";
			Code += "MOV AH,2\n";
			Code += "MOV DL, 0AH \n";
			Code += "INT 21H \n";
		}
		else
		{
			Code += "MOV AH,2\n";
			Code += "MOV DL, 0DH \n";
			Code += "INT 21H \n";	
			Code += "MOV AH,2\n";
			Code += "MOV DL, 0AH \n";
			Code += "INT 21H \n";
			Code += "MOV DL, "+temp->tempName+" \n";
			Code += "INT 21H\n";
		}
	}
	ss->code += Code;
}

void AssemCodeForLoop(SymbolInfo *ss,SymbolInfo *StartCond,SymbolInfo *LoopCond,SymbolInfo *LastCond,SymbolInfo *Body)
{
	string loopStartLabel = LabelGenerator();
	string loopEndLabel = LabelGenerator();
	string Code = "";
	
	Code += StartCond->code+" \n"+loopStartLabel+ ": \n"+LoopCond->code+" \n";
	Code += "MOV AX, "+ LoopCond->tempName+" \n";
	Code += "CMP AX, 0 \n";
	Code += "JE "+loopEndLabel +" \n";
	//condition check over,execute body part	
	Code+= Body->code+"\n" + LastCond->code + " \n";
	// iterate, so jmp to begining of loop
	Code += "JMP "+loopStartLabel + " \n";
	Code += loopEndLabel +": \n";
	
	ss->code = ss->code+Code;
}

void AssemCodeWhileLoop(SymbolInfo *ss,SymbolInfo *LoopCond,SymbolInfo *Body)
{
	string loopStartLabel = LabelGenerator();
	string loopEndLabel = LabelGenerator();
	string Code = "";
	
	Code += loopStartLabel+": \n"+LoopCond->code+" \n";
	Code += "MOV AX, "+ LoopCond->tempName+" \n";
	Code += "CMP AX, 0 \n";
	Code += "JE "+loopEndLabel +" \n";
	Code += Body->code +" \n";
	// iterate, so jmp to begining of loop
	Code += "JMP "+loopStartLabel+" \n";
	Code += loopEndLabel +": \n";
	
	ss->code += Code;
}

SymbolInfo* AssemCodeWhileLoop(SymbolInfo *LoopCond,SymbolInfo *Body)
{
	SymbolInfo *ss = new SymbolInfo();
	ss->code = "";
	string loopStartLabel = LabelGenerator();
	string loopEndLabel = LabelGenerator();
	string Code = "";
	
	Code += loopStartLabel+": \n"+LoopCond->code+" \n";
	Code += "MOV AX, "+ LoopCond->tempName+" \n";
	Code += "CMP AX, 0 \n";
	Code += "JE "+loopEndLabel +" \n";
	Code += Body->code +" \n";
	// iterate, so jmp to begining of loop
	Code += "JMP "+loopStartLabel+" \n";
	Code += loopEndLabel +": \n";
	
	ss->code += Code;
	return ss;
}

void AssemCodeIf(SymbolInfo *ss,SymbolInfo *expr,SymbolInfo *stmt)
{
	string Label2 = LabelGenerator();//if false, then jmp to this label
	string Code = "";

	Code += expr->code+" \n";
	Code += "MOV AX, "+expr->tempName+" \n";
	Code += "CMP AX, 0 \n";
	Code += "JE "+Label2+" \n";
	Code += stmt->code+" \n";
	Code += Label2+": \n";

	ss->code += Code;
}

void AssemCodeIfElse(SymbolInfo *ss,SymbolInfo *expr,SymbolInfo *stmt1,SymbolInfo *stmt2)
{
	string Label2 = LabelGenerator();//if false, then jmp to this label
	string Label1 = LabelGenerator(); // jmp to this if continue
	string Code = "";
	
	Code += expr->code +" \n";
	Code += "MOV AX, "+expr->tempName+" \n";
	Code += "CMP AX, 0 \n";
	Code += "JE "+Label2+" \n"; //else condition satisfied, jmp to label 2
	//if condition satisfied, so execute stmt1 code	
	Code += stmt1->code+" \n"; // now jump to skip label 2, ie, jmp to continue
	Code += "JMP "+Label1+" \n";

	Code += Label2+": \n";
	Code += stmt2->code+" \n";
	Code += Label1+": \n";
	
	ss->code += Code;
}

void AssemCodeArray(SymbolInfo *ss,SymbolInfo *s1)
{
	string temp = newTempVar(); //cout<<"arrrrrrrr called in line "<<line_count<<endl;
	ss->tempName = temp;
	string Code = "";
	Code += "LEA DI, "+s1->name+" \n";
	Code += "ADD DI, "+to_string(s1->index)+" \n";
	Code += "MOV AX, [DI] \n";
	Code += "MOV "+temp+ ", AX \n";
	ss->code+= Code;
	ss->dataType= s1->dataType; ss->intValue = s1->intValue; ss->floatValue = s1->floatValue;ss->charValue = s1->charValue; 
	
}

string to_String(int a)
{
	stringstream ss;
	ss<<a;
	string str = ss.str();
	return str;
}

string LabelGenerator()
{
	string label = "L"+to_string(label_count);
	label_count++;
	return label;
}

string newTempVar()
{
	string temp = "t"+ to_string(temp_count);
	dataCode += temp+" DW ?\n";
	temp_count++;
	return temp;
}
string PRINT = "PRINT PROC\n\n PUSH AX\n\
    PUSH BX\n\
    PUSH DX\n\
    PUSH CX\n\n\
    XOR CX,CX\n\
    XOR DX,DX\n\
    XOR BX,BX\n\
    MOV BX,10D\n\
@REPEAT_P:\n\
    XOR DX,DX\n\
    INC CX\n\
    DIV BX\n\
    PUSH DX\n\
    OR AX,AX\n\
    JZ @PRINTING\n\
    JMP @REPEAT_P\n\n\n    @PRINTING:\n\
    MOV AH,2\n\
    POP DX \n\
    OR DL,30H\n\
    INT 21H\n\
    LOOP @PRINTING\n\n\
    POP CX\n\
    POP DX\n\
    POP BX\n\
    POP AX\n\
    RET\n\
PRINT ENDP\n\n\n";
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE CONST_FLOAT CONST_INT ADDOP DECOP MULOP INCOP RELOP ASSIGNOP LOGICOP NOT COMMA SEMICOLON LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD ID NEWLINE PRINTLN

%nonassoc one
%nonassoc ELSE



%%
start : program
	{
		//write your code in this block in all the similar blocks below
		symbolTable->printAllScope(fp3);
		fprintf(fp3,"\n\nTotal lines: %d",line_count);
		fprintf(fp3,"\nTotal errors: %d",error_count);
	}
	;

program : program unit 
	{
		$$->codeSegment += "\n"+$2->codeSegment; 
		fprintf(fp3,"Line %d: program : program_unit\n\n",line_count);
		fprintf(fp3,"%s\n\n",$$->codeSegment.c_str());
	}
	| unit 
	{
		fprintf(fp3,"Line %d: program : unit\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
	;
	
unit :  var_declaration 
	{
		fprintf(fp3,"Line %d: unit : var_declaration\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
        | func_declaration 
	{
		fprintf(fp3,"Line %d: unit : func_declaration\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
        | func_definition 
	{
		fprintf(fp3,"Line %d: unit : func_definition\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
		{
		;
			$$->codeSegment +=" "+ $2->codeSegment+$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+"\n";
						
			fprintf(fp3,"Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			numOfParameters = paramType.size(); paramIndex = paramName.size();
			// updating the parameters of function ie symbol 2
			$2->dataType=$1->name;
			$2->isFunction=true;
			$2->parameters = numOfParameters;
			for(int i=0;i<numOfParameters;i++)
			{
				$2->paramType.push_back(paramType[i]);
				$2->paramName.push_back(paramName[i]);
			}
			GlobalScopeInsertFunc($2,1);
			paramType.clear();
			paramName.clear();
			symbolTable->printAllScope(fp3);
			symbolTable->ExitScope();
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$$->codeSegment += " "+$2->codeSegment+$3->codeSegment+$4->codeSegment+$5->codeSegment+"\n";
			fprintf(fp3,"Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			$2->isFunction=true;
			$2->parameters = 0;
			$2->dataType=$1->name;
			GlobalScopeInsertFunc($2,1);
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN LCURL
		{
			func=0;
			numOfParameters = paramType.size(); paramIndex = paramName.size();
			// updating the parameters of function ie symbol 2
			$2->dataType=$1->name;
			$2->isFunction=true;
			$2->parameters = numOfParameters;int Idx;
			for(int i=0;i<numOfParameters;i++)
			{
				$2->paramType.push_back(paramType[i]);
				$2->paramName.push_back(paramName[i]);
				Idx = 2*(numOfParameters+2-i);
				paramCode += "MOV AX, [BP+"+to_string(Idx)+"] \n";
				paramCode += "MOV "+paramName[i]+", AX \n";
			}
			GlobalScopeInsertFunc($2,1);
			paramType.clear();
			paramName.clear();
		} statements RCURL
		{
			filelog<<"At line no: "<<line_count<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"<<endl;
			$$->codeSegment = $1->codeSegment+" "+ $2->codeSegment+$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+$8->codeSegment+$9->codeSegment;	
			//2 number e id tai holo function name	
			fprintf(fp3,"Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());			
			/*cout<<"func definition 1 number"<<endl;
			cout<<"1 "<<$1->codeSegment<<endl;
			cout<<"2 "<<$2->codeSegment<<endl;
			cout<<"3 "<<$3->codeSegment<<endl;
			cout<<"4 "<<$4->codeSegment<<endl;
			cout<<"5 "<<$5->codeSegment<<endl;
			cout<<"6 "<<$6->codeSegment<<endl;
			cout<<"7 "<<$7->codeSegment<<endl;
			cout<<"8 "<<$8->codeSegment<<endl;
			cout<<"9 "<<$9->codeSegment<<endl;
			cout<<"func definition 1 shesh"<<endl;*/
			
			endCode += $2->name+" PROC \n\n";
			endCode += "PUSH BP \n";
			endCode += paramCode+stmtCode;
			endCode += $2->name+" ENDP \n\n";
			
			stmtCode = paramCode = "";
			
			symbolTable->printAllScope(fp3);
			symbolTable->ExitScope();
				
		}
		| type_specifier ID LPAREN RPAREN LCURL
		{
			numOfParameters = paramName.size();
			$2->isFunction=true;
			$2->parameters = numOfParameters; $2->dataType=$1->name;
			GlobalScopeInsertFunc($2,1);
			symbolTable->EnterScope(bucketSize);
		} statements RCURL
		{
			$$->codeSegment = $1->codeSegment+" "+$2->codeSegment+$3->codeSegment+$4->codeSegment+$5->codeSegment+$7->codeSegment+$8->codeSegment;	
			fprintf(fp3,"Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			/*cout<<"func definition 2 number"<<endl;
			cout<<"1 "<<$1->codeSegment<<endl;
			cout<<"2 "<<$2->codeSegment<<endl;
			cout<<"3 "<<$3->codeSegment<<endl;
			cout<<"4 "<<$4->codeSegment<<endl;
			cout<<"5 "<<$5->codeSegment<<endl;
			cout<<"6 "<<$6->codeSegment<<endl;
			cout<<"7 "<<$7->codeSegment<<endl;
			cout<<"8 "<<$8->codeSegment<<endl;
			cout<<"func definition 2 shesh"<<endl;*/
		
			
			if($2->name=="main"){  mainCode += stmtCode; }
			else { endCode += $2->name+" PROC\n\n"+stmtCode+"\n\n"+$2->name+" ENDP\n"; }
			stmtCode = "";			
			symbolTable->printAllScope(fp3);			
			symbolTable->ExitScope();
		} 		
;				

parameter_list  : parameter_list COMMA type_specifier ID 
		{ 
			$$->codeSegment += $2->codeSegment+$3->codeSegment+" "+$4->codeSegment;
			//4 numbere thaka id tai holo ekta parameter, tai eke  parameter list e dhukabo
			//cout<<"Inserting parameters "<<$4->name<<endl;
			InsertIdentifier($4);	
			fprintf(fp3,"Line %d: parameter_list : parameter_list COMMA type_specifier ID\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			paramType.push_back($4->dataType);
			paramName.push_back($4->name);
		}
		| parameter_list COMMA type_specifier 
		{ 
			$$->codeSegment += $2->codeSegment+$3->codeSegment;
			fprintf(fp3,"Line %d: parameter_list : parameter_list COMMA type_specifier\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		} 
 		| type_specifier ID 
		{ 
			//4 numbere thaka id tai holo ekta parameter, tai eke  parameter list e dhukabo
			$$->codeSegment += " "+$2->codeSegment;
			//cout<<"Inserting  parameter "<<$2->name<<endl;
			symbolTable->EnterScope(bucketSize);
			InsertIdentifier($2);		
			fprintf(fp3,"Line %d: parameter_list : type_specifier ID\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			paramType.push_back($2->dataType);
			paramName.push_back($2->name);
		}
		| type_specifier 
		{ 
			fprintf(fp3,"Line %d: parameter_list : type_specifier \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			symbolTable->EnterScope(bucketSize);
		}
 		;

 		
compound_statement : LCURL statements RCURL 
		   { 
			$$->codeSegment = $1->codeSegment+$2->codeSegment+$3->codeSegment; 
			fprintf(fp3,"Line %d: compound_statement : LCURL statements RCURL \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			//icg
			$$ = $2;
			//icg
			//symbolTable->printAllScope(fp3);
			//symbolTable->ExitScope();
		   }
 		   | LCURL RCURL 
		   { 
			$$->codeSegment += $1->codeSegment+$2->codeSegment;
			fprintf(fp3,"Line %d: compound_statement : LCURL RCURL \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
		{
			$$->codeSegment += " "+$2->codeSegment+$3->codeSegment+"\n";
			fprintf(fp3,"Line %d: var_declaration : type_specifier declaration_list SEMICOLON \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			//icg
			PseudoAssign($2,$$); delete $1;
		}
 		 ;
 		 
type_specifier	: INT 
		{ 
			dataType = "int";
			fprintf(fp3,"Line %d: type_specifier : INT \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
 		| FLOAT 
		{ 
			dataType = "float";
			fprintf(fp3,"Line %d: type_specifier : FLOAT \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		} 
 		| VOID 
		{ 
			dataType = "void";
			fprintf(fp3,"Line %d: type_specifier : VOID \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
		| CHAR 
		{ 
			dataType = "char";
			fprintf(fp3,"Line %d: type_specifier : CHAR \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
 		;
 		
declaration_list : declaration_list COMMA ID 
		 { 
			$$->codeSegment += $2->codeSegment + $3->codeSegment;
			fprintf(fp3,"Line %d: declaration_list : declaration_list COMMA ID \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			InsertIdentifier($3);
		 }
 		 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
		 {
			$$->codeSegment += $2->codeSegment + $3->codeSegment +$4->codeSegment +$5->codeSegment+$6->codeSegment; 
			ArrayValidate($3,$5);
			fprintf(fp3,"Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
 		  | ID 
		  { 
			fprintf(fp3,"Line %d: declaration_list : ID\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			InsertIdentifier($1);
		  }
 		  | ID LTHIRD CONST_INT RTHIRD 
		  { 
			$$->codeSegment += $2->codeSegment+$3->codeSegment+$4->codeSegment;			
			fprintf(fp3,"Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());

			//processing array
			ArrayValidate($1,$3);
		  }
 		  ;
 		  
statements : statement 
	   { 
		fprintf(fp3,"Line %d: statements : statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str()); 
		//stmtCode += $1->code;
		 $$=$1;
	} 
	   | statements statement 
	   { 
		$$->codeSegment += $2->codeSegment;
		fprintf(fp3,"Line %d: statements : statements statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		stmtCode += $2->code; //$$->code += $2->code;
	   }
	   ;
	   
statement : var_declaration
	  {
		fprintf(fp3,"Line %d: statement : var_declaration\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | expression_statement
	  {
		fprintf(fp3,"Line %d: statement : expression_statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());$$=$1;
	  }
	  | compound_statement
	  {
		fprintf(fp3,"Line %d: statement : compound_statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		$$ = $1;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+$7->codeSegment ;
		fprintf(fp3,"Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		AssemCodeForLoop($$,$3,$4,$5,$7);
	
	  }
          | IF LPAREN expression RPAREN statement %prec one
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment ;
		fprintf(fp3,"Line %d: statement : IF LPAREN expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		AssemCodeIf($$,$3,$5);
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+$7->codeSegment ;
		fprintf(fp3,"Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		AssemCodeIfElse($$,$3,$5,$7);
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		$$->codeSegment +=  $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment ;
		fprintf(fp3,"Line %d: statement : WHILE LPAREN expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		$$=AssemCodeWhileLoop($3,$5);
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		$$->codeSegment += $1->codeSegment +$2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+"\n" ;
		fprintf(fp3,"Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		//icg
		AssemCodePrintln($3,$$);
	  }
	  | RETURN expression SEMICOLON
	  {
		$$->codeSegment = $1->codeSegment +" "+$2->codeSegment +$3->codeSegment+"\n" ;
		fprintf(fp3,"Line %d: statement : RETURN expression SEMICOLON\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  	PseudoAssign($2,$$);
		//icg
		$$->code = $2->code;
	}
	  ;
	  
expression_statement : SEMICOLON 
		    {
			fprintf(fp3,"Line %d: expression_statement : SEMICOLON\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		    } 			
		| expression SEMICOLON 
		{
			$$->codeSegment += ";";$$->codeSegment += "\n";
			fprintf(fp3,"Line %d: expression_statement : expression SEMICOLON\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
		;
	  
variable : ID 
	 {
		$$->codeSegment = $1->codeSegment;
		fprintf(fp3,"Line %d: variable : ID\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		string temp = $$->codeSegment;	
		SymbolInfo *ks = GetIdentifier($1,$$);
		if(ks->arraySize>0)
		{
			yyerror("Type mismatch, "+ks->name+" is an array");
			error_count++;
		}
		
	 }
	 | ID LTHIRD expression RTHIRD
	 {
		$$->codeSegment = $1->codeSegment +$2->codeSegment + $3->codeSegment+ $4->codeSegment; 
		fprintf(fp3,"Line %d: variable : ID LTHIRD expression RTHIRD\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		SymbolInfo* s =NULL;
		s= GetArrayElement($1,$3); //if(s!=NULL)cout<<"returned with value "<<endl;
		string temp = $$->codeSegment;
		string name = $$->name;
	 }
	 ;
	 
expression : logic_expression	
	   {
		fprintf(fp3,"Line %d: expression : logic_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//cout<<"code ========"<<$$->code<<endl;
		
		//PseudoAssign($1,$$); $$->code += $1->code;
		$$=$1;
	   }
	   | variable ASSIGNOP logic_expression 
	   {
		$$->codeSegment = $1->codeSegment +$2->codeSegment + $3->codeSegment;
		fprintf(fp3,"Line %d: expression : variable ASSIGNOP logic_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		if($3->isFunction )
		{
			SymbolInfo *fun= GetFunctionPtr($3);
			if(fun!=NULL)
			{
				if(fun->dataType=="void")
				{  
					yyerror("Void function used in expression ");
					error_count++;
				}
			}
		}
		$$->code += $3->code;
		VariableAssign($1,$3);
		PseudoAssign($1,$$);	
	       //cout<<" expression : variable assignop logic expr  er code "<<$$->code<<endl;	
		
	}	
	   ;
			
logic_expression : rel_expression 
		 {
			fprintf(fp3,"Line %d: logic_expression : rel_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//cout<<"code ========"<<$$->code<<endl;
			
			//cout<<"logic expression : rel expression  er code "<<$$->code<<endl;
		 }	
		 | rel_expression LOGICOP rel_expression 
		 {
			$$->codeSegment = $1->codeSegment +$2->codeSegment + $3->codeSegment;
			fprintf(fp3,"Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			LogicalOpSymbols($1,$2,$3,$$);
		 }	
		 ;
			
rel_expression	: simple_expression  
		{
			fprintf(fp3,"Line %d: rel_expression	: simple_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str()); //cout<<"code = "<<$$->code<<endl;
			
		} 
		| simple_expression RELOP simple_expression 
		{
			$$->codeSegment += $2->codeSegment + $3->codeSegment;
			fprintf(fp3,"Line %d: rel_expression : simple_expression RELOP simple_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			RelopSymbols($1,$2,$3,$$);
		}
		;
				
simple_expression : term 
		  {
			fprintf(fp3,"Line %d: simple_expression : term\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		  }
		  | simple_expression ADDOP term 
		  {
			$$->codeSegment += $2->codeSegment + $3->codeSegment; 
			fprintf(fp3,"Line %d: simple_expression : simple_expression ADDOP term\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		//checking for void function calling
			if($3->isFunction )
			{  
				SymbolInfo *fun= GetFunctionPtr($3);
				if(fun!=NULL)
				{
					if(fun->dataType=="void")
					{  
						yyerror("Void function used in expression ");
						error_count++;
					}
				}
			}
			AddSymbols($1,$2,$3,$$);
		} 
		  ;
					
term :	unary_expression 
	{			
		fprintf(fp3,"Line %d: term : unary_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); //$$->code+= $1->code;
	}
     |  term MULOP unary_expression 
	{
		$$->codeSegment = $1->codeSegment + $2->codeSegment+$3->codeSegment; 
		fprintf(fp3,"Line %d: term : term MULOP unary_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
		if($3->isFunction )
		{  
			SymbolInfo *fun= GetFunctionPtr($3);
			if(fun!=NULL)
			{
				if(fun->dataType=="void")
				{  
					yyerror("Void function used in expression ");
					error_count++;
				}
			}
		}
		//cout<<"calling multiplysymbols with "<<$1->tempName<<" and "<<$3->tempName<<endl;
		//cout<<"term mulop unary expre er ager code = "<<$3->code<<endl;
		$$->code += $3->code;
		MultiplySymbols($1,$2,$3,$$);
	}
     ;

unary_expression : ADDOP unary_expression 
		 {
			$$->codeSegment = $1->codeSegment+$2->codeSegment;
			fprintf(fp3,"Line %d: unary_expression : ADDOP unary_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
			UnaryExpr($1,$2,$$);
		 }
		 | NOT unary_expression 
		 {
			$$->codeSegment = $1->codeSegment+$2->codeSegment;
			fprintf(fp3,"Line %d: unary_expression : NOT unary_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
			UnaryExpr($1,$2,$$);
		 } 
		 | factor 
		 {
			fprintf(fp3,"Line %d: unary_expression : factor \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
			PseudoAssign($1,$$); $$->code = $1->code;
		}
		 ;
	
factor	: variable 
	{
		$$->codeSegment = $$->codeSegment;
		fprintf(fp3,"Line %d: factor : variable \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		if($1->index == -1)//ie not an array
		{
			PseudoAssign($$,$1);	
		}
		else // if it is an array, do as such
		{
			AssemCodeArray($$,$1);
		}

	}
	| ID LPAREN argument_list RPAREN
	{
		$$->codeSegment = $1->codeSegment + $2->codeSegment + $3->codeSegment+ $4->codeSegment;	
		fprintf(fp3,"Line %d: factor : ID LPAREN argument_list RPAREN \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		SymbolInfo *func = GetFunctionPtr($1);
		if(func!=NULL)
		{
			ParametersVerify(func);
			PseudoAssign(func,$$);
			//function er data type ie return type void na hoile call kora jabe
			if(func->dataType!="void")
			{
				//call the corresponding procedure
				$$->code = $3->code;
				$$->code += "CALL "+$1->name+" \n";
			}
		}
	}
	| LPAREN expression RPAREN 
	{
		$$->codeSegment = $1->codeSegment + $2->codeSegment + $3->codeSegment;
		fprintf(fp3,"Line %d: factor : LPAREN expression RPAREN \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str()); 
		PseudoAssign($2,$$);	//cout<<"code ========"<<$$->code<<endl;	
	}
	| CONST_INT 
	{
		fprintf(fp3,"Line %d: factor : variable CONST_INT \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); $$->code += $1->code;
		//cout<<"const int er code =="<<$1->code<<endl;
		
	}
	| CONST_FLOAT 
	{
		fprintf(fp3,"Line %d: factor : variable CONST_FLOAT \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); $$->code += $1->code;
	}
	| variable INCOP 
	{
		$$->codeSegment = $1->codeSegment+$2->codeSegment; 
		fprintf(fp3,"Line %d: factor : variable INCOP\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); 
		//new from icg part,increment handled in this function incopsymbols
		 IncOpSymbol($$,$1);
	}
	| variable DECOP 
	{
		$$->codeSegment = $1->codeSegment+$2->codeSegment; 
		fprintf(fp3,"Line %d: factor : variable DECOP\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$);  
		//new from icg part,increment handled in this function incopsymbols
		 DecOpSymbol($$,$1);
	}
	;
	
argument_list : arguments
		{
			fprintf(fp3,"Line %d: argument_list: arguments\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
		|
	 	;
	
arguments : arguments COMMA logic_expression
	      {
		$$->codeSegment += $2->codeSegment+$3->codeSegment;
		fprintf(fp3,"Line %d: arguments: arguments COMMA logic_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		if($3->dataType=="int" || $3->dataType=="float" || $3->dataType=="char")
		{
			paramType2.push_back($3->dataType);
		}
		else
		{
			string symbolDataType = ExtractDataType($1->name);       	
			if(symbolDataType=="") symbolDataType=dataType;				
			paramType2.push_back(symbolDataType);
		}
		paramName2.push_back($3->name);//cout<<"NN inserting name = "<<$3->name<<endl;
		$$->code += "MOV AX, "+$3->name+"\n";
		$$->code += "PUSH AX \n"; 
	      }
	      | logic_expression
	      {
	      		if($1->dataType=="int" || $1->dataType=="float" || $1->dataType=="char")
			{
				paramType2.push_back($1->dataType);
			}
			else
			{
				string symbolDataType = ExtractDataType($1->name);       	
				if(symbolDataType=="") symbolDataType=dataType;				
				paramType2.push_back(symbolDataType);
			}
			fprintf(fp3,"Line %d: arguments: logic_expression rel_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			paramName2.push_back($1->name);
			//icg
			$$->code += "MOV AX, "+$1->name+" \n";
			$$->code += "PUSH AX \n";
	      }
	      ;
 
%%

int main(int argc,char *argv[])
{
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}


	fp3 = fopen("log.txt","w");
	fp4 = fopen("error.txt","w");
	fp2 = fopen("code.asm","w");
	yyin=fp;
	yyparse();

	
	
	dataCode = dataCode +"\n";
	string asmCode;
	//cout<<"Init code = "<<initCode<<endl;
	//cout<<"data code = "<<dataCode<<endl;
	//cout<<"main code = "<<mainCode<<endl;
	//cout<<"end code = "<<endCode<<endl;
	asmCode = initCode + dataCode + mainCode;
	asmCode += "\nMOV AH,4CH\nINT 21H \n\n";
	asmCode += PRINT+"END MAIN \n\n"+endCode;
	//cout<<dataCode<<endl;

	fprintf(fp2,"%s",asmCode.c_str());
	return 0;
}
