#include<bits/stdc++.h>
using namespace std;
typedef long long ll;
class SymbolInfo
{
public:
	string name,type,dataType,codeSegment,code,tempName;
	int intValue = -1,index;
	float floatValue;
	char charValue;
	int arraySize=-1;
	SymbolInfo *nextSymbol;
	int parameters=0;
	bool isFunction=false;
	SymbolInfo* Array;
	vector<string> paramType;
	vector<string> paramName;

    SymbolInfo(string name,string type)
    {
        this->name = name;
        this->type = type;
	this->codeSegment = name;
	isFunction = false;
        nextSymbol = NULL;
	
	this->code="";
	tempName= name;
	index = -1;	
	
    }
    SymbolInfo()
    {
    }
    SymbolInfo(const SymbolInfo &symbol)
    {
        cout<<"Copy constructor called"<<endl;
        name = symbol.name;
        type = symbol.type;
        nextSymbol = symbol.nextSymbol;
    }
    void setName(string name)
    {
        this->name = name;
    }
    void setType(string type)
    {
        this->type = type;
    }
    void setNextSymbol(SymbolInfo *symbolInfo)
    {
        this->nextSymbol = symbolInfo;
        if(nextSymbol==NULL)
        {
            cout<<"Memory allocation failed"<<endl;
        }
    }
    SymbolInfo *getNextSymbol()
    {
        return nextSymbol;
    }
    string getName()
    {
        return this->name;
    }
    string getType()
    {
        return this->type;
    }
    void setNexttoNull()
    {
        this->nextSymbol = NULL;
    }
    void constructArray()
    {
	Array = new SymbolInfo[arraySize+1];
	for(int i=0;i<=arraySize;i++)
	{
		//cout<<"making array with index "<<i<<endl;
		Array[i].dataType = dataType;	//cout<<"data type given "<<Array[i].dataType<<endl;
		if(dataType == "int") {Array[i].intValue =-1; /*cout<<"-1 int value given"<<endl;*/}
		else if(dataType =="float") {Array[i].floatValue = -1; /*cout<<"-1 float value given"<<endl;*/}
		else if(dataType == "char") {Array[i].charValue = '!'; /*cout<<"-1 int char given"<<endl;*/}
		Array[i].name = this->name;
		Array[i].type = this->type;
	}
    }

    SymbolInfo* getArrayElement(int index)
    { 
	if(index ==0 ) index++;
	SymbolInfo* s =&(Array[index]);
	//cout<<"get called with index "<<index<<endl; 
	//if(&(Array[index])==NULL) cout<<"                          array element null"<<endl;
	//else {cout<<"not null array element "<<endl;	}
	return &(Array[index]); 
    }
    ~SymbolInfo()
    {
        //cout<<"destructor called for symbol table"<<endl;
        delete nextSymbol;
    }
};
