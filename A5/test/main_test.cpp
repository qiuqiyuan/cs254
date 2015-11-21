#include "gtest/gtest.h"
#include "oset/oset.hpp"
#include <vector>
#include <iostream>
#include <string>
using std::vector;
using std::string;
using std::cout;
using std::endl;

class OsetTest : public ::testing::Test {
    protected:
        oset os;
        void virtual SetUp(){}
        void virtual TearDown(){}
};

TEST_F(OsetTest, InsertWithOrder){
    vector<int> s_init = {3,2,4,5,7,3};
    for(auto &&it:s_init) os += it;

    vector<int> s_res = {2,3,4,5,7};

    int i = 0;
    for(auto it = os.begin(); it != os.end(); it++){
        EXPECT_EQ(*it, s_res[i]);
        ++i;
    }
}

TEST_F(OsetTest, UnionTest){
    vector<int> vu = {2, 6, 10};
    vector<int> vv = {6, 7};
    vector<int> vres = {2, 6, 7, 10};
    oset osu, osv, ores;
    for(auto &&it:vu) osu += it;
    for(auto &&it:vv) osv += it;
    for(auto &&it:vres) ores += it;

    //union osu with osv
    osu += osv;

    int i = 0;
    for(auto it = ores.begin(); it != ores.end(); it++){
        EXPECT_EQ(*it, vres[i]);
        ++i;
    }
}

TEST_F(OsetTest, UnionEmpty){
    vector<int> vu;
    vector<int> vv = {2, 6, 10};
    vector<int> vres = {2, 6, 10};
    oset osu, osv, ores;
    for(auto &&it:vu) osu += it;
    for(auto &&it:vv) osv += it;
    for(auto &&it:vres) ores += it;

    //union osu with osv
    osu += osv;

    int i = 0;
    for(auto it = ores.begin(); it != ores.end(); it++){
        EXPECT_EQ(*it, vres[i]);
        ++i;
    }
}

int main(int argc, char* argv[]){
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
