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

extern FILE *yyin;
extern int line_count;
extern int error_count;

void yyerror(string s){
	fprintf(fp3,"Error at line %d: %s\n\n",line_count,s.c_str());
	fprintf(fp4,"Error at line %d: %s\n\n",line_count,s.c_str());
	//fileerror<<s<<"errorfound at line number = "<<line_count<<" "<<s<<"\n"<<endl;
	//filelog<<s<<"errorfound at line number = "<<line_count<<" "<<s<<"\n"<<endl;
	//printf("%s ",s);cout<<"at line number = "<<line_count<<endl;
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
	int nop = paramType2.size();//cout<<"GG exst name "<<exst->name<<" er pno = "<<exst->parameters<<" nop= "<<nop<<"  line no = "<<line_count<<endl;
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
			//cout<<"uuu rela "<<exst->paramType[i]<<" and new = "<<paramType2[i]<<"  line "<<line_count<<endl; 
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
	//cout<<"function "<<exst->name<<" er type = "<<exst->dataType<<" and new name now "<<nw->name<<" dataType= "<<nw->dataType<<endl;
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
	//cout<<"GlobalScopeInsertFunc called with "<<s->name<<" and size "<<s->paramType.size()<<endl;
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
		//cout<<"VVVVV verify korar aage "<<t->name <<" er isfunction "<<t->isFunction<<endl;
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
		//cout<<"xxfunction "<<s->name<<" not inserted successfully"<<endl;
		//cout<<"newly "<<s->name<<" er datatype = "<<s->dataType<<endl;
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
	status = symbolTable->Insert(si);
	//if(status) cout<<"Symbol "<<si->name<<" inserted true"<<endl;
	//else  	cout<<"Symbol "<<si->name<<" inserted false"<<endl;
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
	}
	else{
		//cout<<"array not inserted"<<endl;
	}
}

void VariableAssign(SymbolInfo* s1,SymbolInfo* s2)
{
	//cout<<"variable assign called with value 11111 "<<s1->name<<" and "<<s1->dataType<<"-------line = "<<line_count<<endl;
	//cout<<"variable assign called with value 22222 "<<s2->name<<" and "<<s2->dataType<<endl;
	SymbolInfo* ts1,*ts2; //s1 is in the symbol table but s2 is not
	ts1=ts2=NULL;
	ts1 = symbolTable->Lookup(s1->name);
	ts2 = symbolTable->Lookup(s2->name);
	if(ts1!=NULL && ts2!=NULL)
	{    
		s1=ts1; s2= ts2;
		//cout<<"11111 found "<<ts1->name<<" and data type "<<ts1->dataType<<" and ara size = "<<ts1->arraySize<<endl;
		//cout<<"22222 found "<<ts2->name<<" and data type "<<ts2->dataType<<" and ara size = "<<ts2->arraySize<<endl;	
	}
	if(ts1==NULL)//cout<<"ts1 is not null:: namae = "<<ts1->name<<" and array size of ts1 "<<ts1->arraySize<<endl;
	{
		yyerror("Undeclared variable "+s1->name);
		error_count++;
		return ;
	} 
	//cout<<"s2 er data type "<<s2->dataType<<endl;	
	if(ts1->arraySize >0 && s2->arraySize>0 && (ts1->name!=s2->name ))
	{
		//cout<<" first segment "<<s1->name<<" and 2nd segment "<<s2->name<<endl;	
		//cout<<"hhhhhhhhh line number "<<line_count<<endl;
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
	//if(ts1->dataType=="int" && s2->dataType=="float") { ts1->intValue = s2->floatValue; }
	if(ts1->dataType=="int" && s2->dataType=="char") { ts1->intValue = s2->charValue; }
	if(ts1->dataType=="float" && s2->dataType=="int") { ts1->floatValue = s2->intValue; }
	if(ts1->dataType=="float" && s2->dataType=="float") { ts1->floatValue = s2->floatValue; }
	if(ts1->dataType=="float" && s2->dataType=="char") { ts1->floatValue = s2->charValue; }
	if(ts1->dataType=="char" && s2->dataType=="int") { ts1->charValue = s2->intValue; }
	if(ts1->dataType=="char" && s2->dataType=="float") { ts1->charValue = s2->floatValue; }
	if(ts1->dataType=="char" && s2->dataType=="char") { ts1->charValue = s2->charValue; }
	s1 = ts1;
	//cout<<"kaj shesh:: s1 name "<<s1->name<<" and value = "<<s1->intValue<<endl;
}

SymbolInfo* GetArrayElement(SymbolInfo* s1,SymbolInfo *s2)
{
	//cout<<"get array element called with "<<s1->name<<" and index ="<<s2->intValue<<"  line "<<line_count<<endl;
	SymbolInfo* temp = NULL;
	int idx = s2->intValue;
	temp = symbolTable->Lookup(s1->name); 
	//cout<<"temp er name = "<<temp->name<<" and size "<<temp->arraySize<<endl;
	if(temp==NULL)
	{
		yyerror("Array "+s1->name+" is not declared in this scope");//cout<<"error 1"<<endl;
		error_count++;
		return temp;
	}
	else if(s2->dataType!="int")
	{
		yyerror("Expression inside third brackets not an integer ie, Array index must be integer");//cout<<"error 2"<<endl;
		error_count++;
		return temp;
	}
	else if(temp->arraySize==-1)
	{
		yyerror(s1->name+" is not an array");//cout<<"error 3"<<endl;
		error_count++;
		return temp;
	}
	else if(idx>=temp->arraySize || idx<0)
	{
		yyerror("Invalid array index");//cout<<"error 4"<<endl;
		error_count++;
		return temp;
	}
	//cout<<"Temp er name = "<<temp->name<<endl;
	//cout<<"Temp er array size "<<temp->arraySize<<endl;
	return temp->getArrayElement(idx);
}
SymbolInfo* GetIdentifier(SymbolInfo* s,SymbolInfo* ss)
{
	//cout<<" get identifier called with name "<<s->name<<endl;
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
		//cout<<"pawa gelo key :: name = "<<key->name<<" and data type = "<<key->dataType<<" and value = "<<key->intValue<<endl;
		return key;
	}
	else
	{
		//yyerror(s->name+" variable is not declared");
		//error_count++;
		return emptySymbol;
	}
}

void AddSymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{
	//cout<<"add called with "<<s1->name<<" and "<<s3->name<<endl;
	//cout<<" data types are "<<s1->dataType<<" and "<<s3->dataType<<endl;
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
	}
	//cout<<"add ended with $$ intValue= "<<s4->intValue<<" and datatype "<<s4->dataType<<endl;
}

void MultiplySymbols(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3,SymbolInfo* s4)
{	
	//cout<<"multiply called with "<<s1->name<<" and "<<s3->name<<" line no------------ "<<line_count<<endl;
	//cout<<" data types are "<<s1->dataType<<" and "<<s3->dataType<<endl;
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
		//cout<<"multiply ended with $$ intValue= "<<s4->intValue<<" and datatype "<<s4->dataType<<endl;
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
	}
	//cout<<"multiply ended with $$ intValue= "<<s4->intValue<<" and datatype "<<s4->dataType<<endl;
	//cout<<"multiply ended with $$ floatValue= "<<s4->floatValue<<" and datatype "<<s4->dataType<<endl;
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
	//cout<<"logical sheshe symbol  "<<s2->name<<" s1= "<<s1->intValue<<" s3= "<<s3->intValue<<" s4 = "<<s4->intValue<<endl;
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
	//cout<<"relop sheshe symbol  "<<s2->name<<" s1= "<<s1->intValue<<" s3= "<<s3->intValue<<" s4 = "<<s4->intValue<<endl;
}
void UnaryExpr(SymbolInfo *s1,SymbolInfo *s2,SymbolInfo *ss)
{
	//cout<<"XXunary called with "<<s1->name<<" and "<<s2->name<<endl;
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
	}
	else if(s1->name=="!")
	{
		ss->dataType="int";
		if(s2->dataType=="int") ss->intValue = !s2->intValue;
		if(s2->dataType=="float") ss->intValue = !s2->floatValue;
		if(s2->dataType=="char") ss->intValue = !s2->charValue;
	}
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
	//cout<<"Get function pointer found "<<temp->name<<" and data type= "<<temp->dataType<<endl;
	//cout<<"ZZ parameter shonkha "<<temp->parameters<<" "<<temp->paramType.size()<<endl;	
	return temp;
}
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
		//filelog<<"At line no: "<<line_count<<" program : program_unit\n"<<endl;		
		$$->codeSegment += "\n"+$2->codeSegment; 
		//filelog<<$$->codeSegment<<"\n"<<endl;		
		fprintf(fp3,"Line %d: program : program_unit\n\n",line_count);
		fprintf(fp3,"%s\n\n",$$->codeSegment.c_str());
	}
	| unit 
	{
		//filelog<<"At line no: "<<line_count<<" program : unit\n"<<endl;	
		//filelog<<$$->codeSegment<<"\n"<<endl;		
		fprintf(fp3,"Line %d: program : unit\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
	;
	
unit :  var_declaration 
	{
		//filelog<<"At line no: "<<line_count<<" unit : var_declaration\n"<<endl;
		//filelog<<$$->codeSegment<<"\n"<<endl;		
		fprintf(fp3,"Line %d: unit : var_declaration\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
        | func_declaration 
	{
		//filelog<<"At line no: "<<line_count<<" unit : func_declaration\n"<<endl;
		//filelog<<$$->codeSegment<<"\n"<<endl;		
		fprintf(fp3,"Line %d: unit : func_declaration\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
        | func_definition 
	{
		//filelog<<"At line no: "<<line_count<<" unit : func_definition\n"<<endl;
		//filelog<<$$->codeSegment<<"\n"<<endl;		
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
			$2->parameters = numOfParameters;
			for(int i=0;i<numOfParameters;i++)
			{
				$2->paramType.push_back(paramType[i]);
				$2->paramName.push_back(paramName[i]);
			}
			GlobalScopeInsertFunc($2,1);
			paramType.clear();
			paramName.clear();
		} statements RCURL
		{
			filelog<<"At line no: "<<line_count<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"<<endl;
			//$$->name = $1->name+" "+ $2->name+$3->name+$4->name+$5->name+$6->name;
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
			//cout<<"pushing into vectorr "<<$4->name<<" "<<$4->dataType<<endl;
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
			//cout<<"pushing into vector "<<$2->name<<" "<<$2->dataType<<endl;
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

 		
compound_statement : LCURL
		   {
			symbolTable->EnterScope(bucketSize);
		   } statements RCURL 
		   { 
			$$->codeSegment = $1->codeSegment+$2->codeSegment+$3->codeSegment; 
			fprintf(fp3,"Line %d: compound_statement : LCURL statements RCURL \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			symbolTable->printAllScope(fp3);
			symbolTable->ExitScope();
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
			//cout<<"Inserting "<<$3->name<<endl;
			InsertIdentifier($3);
		 }
 		 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
		 {
			$$->codeSegment += $2->codeSegment + $3->codeSegment +$4->codeSegment +$5->codeSegment+$6->codeSegment; 
			//processing array
			//cout<<"array name "<<$3->name<<" size "<<$5->intValue<<endl;
			ArrayValidate($3,$5);
			fprintf(fp3,"Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		}
 		  | ID 
		  { 
			fprintf(fp3,"Line %d: declaration_list : ID\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
			//cout<<"Inserting "<<$1->name<<endl;
			InsertIdentifier($1);
		  }
 		  | ID LTHIRD CONST_INT RTHIRD 
		  { 
			$$->codeSegment += $2->codeSegment+$3->codeSegment+$4->codeSegment;			
			fprintf(fp3,"Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());

			//processing array
			//cout<<"array name "<<$1->name<<" size "<<$3->intValue<<endl;
			ArrayValidate($1,$3);
		  }
 		  ;
 		  
statements : statement 
	   { 
		//filelog<<"At line no: "<<line_count<<" statements : statement\n"<<endl;
		fprintf(fp3,"Line %d: statements : statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	   } 
	   | statements statement 
	   { 
		$$->codeSegment += $2->codeSegment;
		fprintf(fp3,"Line %d: statements : statements statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
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
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | compound_statement
	  {
		fprintf(fp3,"Line %d: statement : compound_statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+$7->codeSegment ;
		fprintf(fp3,"Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	
	  }
          | IF LPAREN expression RPAREN statement %prec one
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment ;
		fprintf(fp3,"Line %d: statement : IF LPAREN expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		$$->codeSegment += $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+$6->codeSegment+$7->codeSegment ;
		fprintf(fp3,"Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		$$->codeSegment +=  $2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment ;
		fprintf(fp3,"Line %d: statement : WHILE LPAREN expression RPAREN statement\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		$$->codeSegment += $1->codeSegment +$2->codeSegment +$3->codeSegment+$4->codeSegment+$5->codeSegment+"\n" ;
		fprintf(fp3,"Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  }
	  | RETURN expression SEMICOLON
	  {
		$$->codeSegment = $1->codeSegment +" "+$2->codeSegment +$3->codeSegment+"\n" ;
		fprintf(fp3,"Line %d: statement : RETURN expression SEMICOLON\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	  	PseudoAssign($$,$2);
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
	 // call dilei x-5;y=x-5; er problem dekhay, tai $$ e return pointer na assign kore $$ parameter e pathay oikhane $$ er filed gula update kore dilam
		
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
		//$$=s; $$->codeSegment = temp;$$->name = name; 
		//cout<<"$$ info name = "<<$$->name<<" and code segment = "<<$$->codeSegment<<endl;		
		// s k $$ e assign kore dite hobe, ekhon s holo non empty ekta symbol but er kono attribute nai
	 }
	 ;
	 
expression : logic_expression	
	   {
		fprintf(fp3,"Line %d: expression : logic_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	   }
	   | variable ASSIGNOP logic_expression 
	   {
		$$->codeSegment = $1->codeSegment +$2->codeSegment + $3->codeSegment;
		fprintf(fp3,"Line %d: expression : variable ASSIGNOP logic_expression\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		//cout<<" assigning a datatype item of "<<$3->dataType<<" name = "<<$3->name<<" function = "<<$3->isFunction<<endl;
		
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
		VariableAssign($1,$3);
		PseudoAssign($$,$1);	
		
	}	
	   ;
			
logic_expression : rel_expression 
		 {
			fprintf(fp3,"Line %d: logic_expression : rel_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		
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
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
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
	}
     |  term MULOP unary_expression 
	{
		//filelog<<"At line no: "<<line_count<<" term : term MULOP unary_expression\n"<<endl;
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
			//filelog<<"At line no: "<<line_count<<" unary_expression : NOT unary_expression\n"<<endl;
			$$->codeSegment = $1->codeSegment+$2->codeSegment;
			fprintf(fp3,"Line %d: unary_expression : NOT unary_expression\n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
			UnaryExpr($1,$2,$$);
		 } 
		 | factor 
		 {
			//filelog<<"At line no: "<<line_count<<" unary_expression : factor "<<endl;
			fprintf(fp3,"Line %d: unary_expression : factor \n\n",line_count);
			fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());//checking for void function calling
		}
		 ;
	
factor	: variable 
	{
		$$->codeSegment = $$->codeSegment;
		fprintf(fp3,"Line %d: factor : variable \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$);

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
		}
	}
	| LPAREN expression RPAREN 
	{
		$$->codeSegment = $1->codeSegment + $2->codeSegment + $3->codeSegment;
		fprintf(fp3,"Line %d: factor : LPAREN expression RPAREN \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
	}
	| CONST_INT 
	{
		fprintf(fp3,"Line %d: factor : variable CONST_INT \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); //cout<<"pseudo assign er pore $$ er value = "<<$$->intValue<<endl;
		
	}
	| CONST_FLOAT 
	{
		fprintf(fp3,"Line %d: factor : variable CONST_FLOAT \n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$);
	}
	| variable INCOP 
	{
		$$->codeSegment = $1->codeSegment+$2->codeSegment; 
		fprintf(fp3,"Line %d: factor : variable INCOP\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); $$->intValue =$$->intValue+1;
	}
	| variable DECOP 
	{
		//filelog<<"At line no: "<<line_count<<" factor : variable DECOP\n"<<endl;
		$$->codeSegment = $1->codeSegment+$2->codeSegment; 
		fprintf(fp3,"Line %d: factor : variable DECOP\n\n",line_count);
		fprintf(fp3,"%s\n\n\n",$$->codeSegment.c_str());
		PseudoAssign($1,$$); $$->intValue =$$->intValue-1;
	}
	;
	
argument_list : arguments
		{
			//filelog<<"At line no: "<<line_count<<"  argument_list: arguments"<<"\n"<<endl;
			//filelog<<$$->codeSegment<<"\n"<<endl;
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
		//cout<<"VVargument here "<<$3->codeSegment<<" int value "<<$3->intValue<<"data type = "<<$3->dataType<<" at line "<<line_count<<endl;
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
			paramName2.push_back($1->name);//cout<<"NN inserting name = "<<$1->name<<endl;
			//cout<<"VV argument here "<<$1->name<<" data type = "<<symbolDataType<<" at line "<<line_count<<endl;
	      }
	      ;
 
%%

int main(int argc,char *argv[])
{
    //yyparse();
    //exit(0);
	
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	//fp2= fopen("table.txt","w");
	//fclose(fp2);
	//fp3= fopen(argv[3],"w");
	//fclose(fp3);

	//filelog.open(argv[2]);
	//fileerror.open(argv[3]);

	fp3 = fopen("log.txt","w");
	fp4 = fopen("error.txt","w");
	
	//fp2= fopen(argv[2],"a");
	//fp3= fopen(argv[3],"a");


	yyin=fp;
	yyparse();


	//fclose(fp3);

	return 0;
}
