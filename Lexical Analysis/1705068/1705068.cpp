#include<bits/stdc++.h>
#include<fstream>
using namespace std;
typedef long long ll;
int rootId=0;
int getHashvalue(string name,int bucketSize);
ofstream file;
bool globalFound=false;
class SymbolInfo
{
    string name,type;
    SymbolInfo *nextSymbol;
public:
    SymbolInfo(string name,string type)
    {
        this->name = name;
        this->type = type;
        nextSymbol = NULL;
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
    ~SymbolInfo()
    {
        //cout<<"destructor called for symbol table"<<endl;
        delete nextSymbol;
    }
};


///ScopeTable
class ScopeTable
{
    int bucketSize;
    string id="";
    int currentId;
    SymbolInfo** hashTable;
    ScopeTable *parentScopeTable;
public:
    ScopeTable(int bucketSize);
    bool Insert(string symbolName,string symbolType);
    void printScopeTable();
    SymbolInfo* Lookup(string );
    bool Delete(string symbolName);
    void setParentScopeTable(ScopeTable *scopeTable);
    void setParentScopeTableNull();
    ScopeTable* getParentScopeTable();
    int getCurrentId(){ return currentId; }
    string getId();
    void setId();
    void increaseCurrentId() { currentId++; }
    int getBucketSize(){ return bucketSize;}
    ~ScopeTable();
};
ScopeTable::ScopeTable(int bucketSize)
{
    this->bucketSize = bucketSize;
    hashTable = new SymbolInfo*[bucketSize];
    parentScopeTable = NULL;
    currentId = 0;
    id="";
    for(int i=0;i<bucketSize;i++)
    {
        hashTable[i] = NULL;
    }
}
SymbolInfo* ScopeTable::Lookup(string symbolName)
{
    bool found =false;int pos=0;
    int bucket = getHashvalue(symbolName,bucketSize);
    string tempName;
    if(hashTable[bucket]==NULL)
    {
        ///not found
        cout<<"NOT FOUND"<<endl;
        return NULL;
    }
    else
    {
        SymbolInfo *temp;
        temp = hashTable[bucket];
        while(temp!=NULL)
        {
            tempName = temp->getName();
            if(tempName==symbolName)
            {
                cout<<"Found is ScopeTable# "<<id<<" at position "<<bucket<<","<<pos<<endl;
                found = true;
                return temp;
            }
            temp = temp->getNextSymbol();pos++;
        }
        return NULL;
    }
}
bool ScopeTable::Insert(string symbolName,string symbolType)
{
    string tempName;
    int bucket = getHashvalue(symbolName,bucketSize);
    int pos=0;
    bool found=false; globalFound=false;
    if(hashTable[bucket]==NULL)
    {
        hashTable[bucket] = new SymbolInfo(symbolName,symbolType);
        ///file<<"Inserted at ScopeTable# "<<id<<" at position "<<bucket<<",0"<<endl;
        //cout<<"Inserted at ScopeTable# "<<id<<" at position "<<bucket<<",0"<<endl;
        //cout<<"line 106::new entry name = "<<hashTable[bucket]->getName()<<endl;
        globalFound=true;
        return true;
    }
    else
    {
        //if exists already, do not insert
        SymbolInfo *temp,*lastSymbol;
        temp = hashTable[bucket];
        while(temp!=NULL)
        {
            tempName = temp->getName();
            if(tempName==symbolName)
            {
                //cout<<"already exists"<<endl;
                file<<symbolName<<" already exists in current ScopeTable\n"<<endl;
                found = true;
                globalFound =false;
                return false;
            }
            lastSymbol = temp;
            temp = temp->getNextSymbol();
            pos++;
        }
        lastSymbol->setNextSymbol(new SymbolInfo(symbolName,symbolType));
        ///file<<"Inserted at ScopeTable# "<<id<<" at position "<<bucket<<","<<pos<<endl;
        //cout<<"Inserted at ScopeTable# "<<id<<" at position "<<bucket<<","<<pos<<endl;
        //cout<<"New inserted name= "<<lastSymbol->getNextSymbol()->getName()<<endl;
        globalFound=true;
        return true;
    }
}
void ScopeTable::printScopeTable()
{
    int i,flagg=0;
    SymbolInfo *temp,*current;
    //cout<<"ScopeTable# "<<id<<endl;
    file<<"ScopeTable# "<<id<<endl;
    //cout<<"Bucket Size = "<<bucketSize<<endl;
    for(i=0;i<bucketSize;i++)
    {
        temp = hashTable[i]; flagg=0;
        //cout<<i<<" -->";
        ///file<<i<<" -->";
        if(temp!=NULL)
        {
            file<<" "<<i<<" -->"; flagg=1;
            current = temp;
            while(current!=NULL)
            {
                string name = current->getName();
                string type = current->getType();
                //cout<<" <"<<name<<":"<<type<<"> ";
                file<<" < "<<name<<" : "<<type<<"> ";
                current = current->getNextSymbol();
            }
        }
        //cout<<endl;
        if(flagg==1)
            file<<endl;
    }
    file<<endl;
}
bool ScopeTable::Delete(string symbolName)
{
    string tempName;
    int bucket = getHashvalue(symbolName,bucketSize);
    int pos=0;
    bool found=false;
    if(hashTable[bucket]==NULL)
    {
        cout<<"NOT FOUND"<<endl;
        return false;
    }
    else
    {
        SymbolInfo *temp,*prevSymbol,*secondSymbol;
        temp = hashTable[bucket];
        ///if the first entry is the symbol to be deleted
        if(temp->getName()==symbolName )
        {
            ///if it is the only entry,make the bucket entry point to null
            if(temp->getNextSymbol()==NULL)
            {
                cout<<"Deleted entry "<<bucket<<","<<pos<<" from current ScopeTable"<<endl;
                hashTable[bucket]=NULL;
                return true;
            }
            else
            {
                secondSymbol = temp->getNextSymbol();
                hashTable[bucket] = secondSymbol;
                cout<<"Deleted entry "<<bucket<<","<<pos<<" from current ScopeTable"<<endl;
                //cout<<"deleted from case 2"<<endl;
                ///make the begining of the bucket point to second entry
                ///testing destructor call
               /// temp->~SymbolInfo();
                return true;
            }
        }
        else
        {
            ///traverse and keep track of the current and its previous pointer
            temp = hashTable[bucket];
            while(temp!=NULL)
            {
                tempName = temp->getName();
                if(tempName==symbolName)
                {
                    found = true;
                    break;
                }
                prevSymbol = temp;
                temp = temp->getNextSymbol();
                pos++;
            }
            if(found)
            {
                /// 1 pointing to 3;
                secondSymbol = temp->getNextSymbol();
                if(secondSymbol==NULL)
                {
                    prevSymbol->setNexttoNull();
                }
                else
                {
                    prevSymbol->setNextSymbol(secondSymbol);
                    ///testing destructor calling
                    ///temp->~SymbolInfo();
                }
                cout<<"Deleted entry "<<bucket<<","<<pos<<" from current ScopeTable"<<endl;
                return true;
            }
            else
            {
                //cout<<"Not present in the entire list"<<endl;
                return false;
            }
        }
    }
}
int getHashvalue(string name,int bucketSize)
{
    int sum=0, n= name.length();
    for(int i=0;i<n;i++)
    {
        sum+=name[i];
    }
    return sum%bucketSize;
}
void ScopeTable::setParentScopeTable(ScopeTable *scopeTable)
{
    parentScopeTable = scopeTable;
}
void ScopeTable::setParentScopeTableNull()
{
    parentScopeTable = NULL;
}
ScopeTable* ScopeTable::getParentScopeTable()
{
    return parentScopeTable;
}
string ScopeTable::getId()
{
    return id;
}
void ScopeTable::setId()
{
    if(parentScopeTable==NULL)
    {
        rootId++;
        id=to_string(rootId);
    }else{
        string a = parentScopeTable->id;
        int children = parentScopeTable->getCurrentId();
        string b = to_string(children);
        id = a+"."+b;
    }
}
ScopeTable::~ScopeTable()
{
    for(int i=0;i<bucketSize;i++)
    {
        delete hashTable[i];
    }
    delete[] hashTable;
    //delete parentScopeTable;
}


///SymbolTable
class SymbolTable{
    ScopeTable *currentScopeTable;
public:
    SymbolTable(int);
    void EnterScope(int);
    void printCurrentScope();
    void printAllScope();
    void printAllScopeIf();
    bool Insert(string symbolName,string symbolType);
    SymbolInfo* Lookup(string symbolName);
    bool Remove(string symbolName);
    void ExitScope();
    void PrintLog(int lineNo,string token,string lexeme);
    ~SymbolTable() { delete currentScopeTable; }
};
SymbolTable::SymbolTable(int n)
{
    ScopeTable *newScope = new ScopeTable(n);
    newScope->setParentScopeTable(currentScopeTable);
    currentScopeTable = newScope;
    if(newScope->getParentScopeTable()!=NULL)
    {
        newScope->getParentScopeTable()->increaseCurrentId();
    }
    currentScopeTable->setId();
    //cout<<"New ScopeTable with id "<<currentScopeTable->getId()<<" created"<<endl;
    file<<"New ScopeTable with id "<<currentScopeTable->getId()<<" created"<<endl;
}
void SymbolTable::EnterScope(int n)
{
    ScopeTable *newScope = new ScopeTable(n);
    newScope->setParentScopeTable(currentScopeTable);
    currentScopeTable = newScope;
    if(newScope->getParentScopeTable()!=NULL)
    {
        newScope->getParentScopeTable()->increaseCurrentId();
    }
    currentScopeTable->setId();
    //cout<<"New ScopeTable with id "<<currentScopeTable->getId()<<" created"<<endl;
    ///file<<"New ScopeTable with id "<<currentScopeTable->getId()<<" created"<<endl;
}
void SymbolTable::printCurrentScope()
{
    if(currentScopeTable==NULL)
    {
        cout<<"this scope is null"<<endl;
    }
    else{
        currentScopeTable->printScopeTable();
    }
}
void SymbolTable::printAllScope()
{
    ScopeTable *temp= currentScopeTable;
    while(temp!=NULL)
    {
        temp->printScopeTable();
        temp = temp->getParentScopeTable();
    }
}
void SymbolTable::printAllScopeIf()
{
    if(globalFound) printAllScope();
}
bool SymbolTable::Insert(string symbolName,string symbolType)
{
    if(currentScopeTable==NULL)
    {
        return false;
    }
    return currentScopeTable->Insert(symbolName,symbolType);
}
bool SymbolTable::Remove(string symbolName)
{
    if(currentScopeTable==NULL)
    {
        return false;
    }
    return currentScopeTable->Delete(symbolName);
}
void SymbolTable::ExitScope()
{
    if(currentScopeTable!=NULL)
    {
        //file<<"ScopeTable with id "<<currentScopeTable->getId()<<" removed"<<endl;
        currentScopeTable=currentScopeTable->getParentScopeTable();
    }
}
SymbolInfo* SymbolTable::Lookup(string symbolName)
{
    ScopeTable *temp;
    SymbolInfo *key;
    temp = currentScopeTable;
    while(temp!=NULL)
    {
        key = temp->Lookup(symbolName);
        if(key!=NULL){
            return key;
        }
        temp=temp->getParentScopeTable();
    }
    return NULL;
}
void SymbolTable::PrintLog(int lineNo,string token,string lexeme)
{
    file<<"Line no "<<lineNo<<" :Token <"<<token<<"> Lexeme "<<lexeme<<" found\n"<<endl;
}
void PrintFinal(int lines,int errors)
{
    file<<"Total lines: "<<lines<<endl;
    file<<"Total errors: "<<errors<<endl;
}
void ErrorPrint(int lineNo,int num,string errorString)
{
    if(num==5){
        file<<"Line no "<<lineNo<<" : Unfinished character error "<<errorString<<"\n"<<endl;
    }
    if(num==6)
    {
        file<<"Line no "<<lineNo<<" : Empty character error "<<errorString<<"\n"<<endl;
    }
    if(num==4)
    {
        file<<"Line no "<<lineNo<<" : Multi character constant error "<<errorString<<"\n"<<endl;
    }
    if(num==7)
    {
        file<<"Line no "<<lineNo<<" : Unfinished string error "<<errorString<<"\n"<<endl;
    }
    if(num==3)
    {
        file<<"Line no "<<lineNo<<" : Invalid Suffix on numeric constant or invalid prefix on identifier "<<errorString<<"\n"<<endl;
    }
    if(num==8)
    {
        file<<"Line no "<<lineNo<<" : Unfinished comment error "<<errorString<<"\n"<<endl;
    }
    if(num==1)
    {
        file<<"Line no "<<lineNo<<" : Too many decimal point error "<<errorString<<"\n"<<endl;
    }
    if(num==2)
    {
        file<<"Line no "<<lineNo<<" : Ill formed number "<<errorString<<"\n"<<endl;
    }
    if(num==9)
    {
        file<<"Line no "<<lineNo<<" : Unrecognized character "<<errorString<<"\n"<<endl;
    }
}
void PrintString(int lineNo,string token,string lexeme,string finalstring)
{
    file<<"Line no "<<lineNo<<" :Token <"<<token<<"> Lexeme "<<lexeme<<" found    < "<<token<<", "<<finalstring<<" >\n"<<endl;
}
/*int main()
{
    int n;
    bool flag;
    string symbolName,symbolType;
    SymbolInfo *symbolInfo;
    freopen("input.txt","r",stdin);
    string line,token;
    vector<string> vs;
    SymbolTable symbolTable;
    while(getline(cin,line))
    {
        vs.clear();
        stringstream tokens(line);
        while(getline(tokens,token,' '))
        {
            vs.push_back(token);
        }
        if(vs[0]!="I" && vs[0]!="L" && vs[0]!="D" && vs[0]!="P" && vs[0]!="A" && vs[0]!="S" && vs[0]!="E" )
        {
            stringstream taken(vs[0]);
            taken>>n;
            symbolTable.EnterScope(n);
        }
        if(vs[0]=="I")
        {
            symbolName = vs[1];
            symbolType = vs[2];
            cout<<vs[0]<<" "<<vs[1]<<" "<<vs[2]<<endl;
            symbolTable.Insert(symbolName,symbolType);
        }
        else if(vs[0]=="L")
        {
            symbolName = vs[1];
            cout<<vs[0]<<" "<<vs[1]<<endl;
            symbolInfo = symbolTable.Lookup(symbolName);
        }
        else if(vs[0]=="D")
        {
            symbolName=vs[1];
            cout<<vs[0]<<" "<<vs[1]<<endl;
            flag = symbolTable.Remove(symbolName);
        }
        else if(vs[0]=="P")
        {
            if(vs[1]=="A"){
                symbolTable.printAllScope();
            }else if(vs[1]=="C"){
                symbolTable.printCurrentScope();
            }
        }
        else if(vs[0]=="S")
        {
            symbolTable.EnterScope(n);
        }
        else if(vs[0]=="E")
        {
            symbolTable.ExitScope();
        }
        cout<<"\n\n"<<endl;
    }
    return 0;
}*/
