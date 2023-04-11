#include <iostream>
#include <string>
#include <cstdio>
#include<fstream>
#include<bits/stdc++.h>
using namespace std;
ofstream file;
int main()
{
    file.open("output.txt");
    int n=2;
    string s,t="hello";
    s=to_string(n);
    s=s+t;
    file<<s<<endl;
    return 0;
}
