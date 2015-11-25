#include "oset/oset.hpp"
#include <iostream>
using std::cout;
using std::endl;
using std::flush;

struct ge {
    bool operator()(const int &a, const int &b) const{
        return a >= b;
    }
};

int main() {
    // Some simple testing code.  You'll need a lot more.

    oset<int> S;     // empty set
    S += 3;     // now should contain 3

    cout << S[3] << " ";            // should print 1 (true) : 3 is in S
    S += 3;                         // should be a no-op
    cout << S[5] << endl;           // should print 0 (false) : 5 not in S

    (S += 5) += 7;
    rprint(S);                       // should print 3 5 7

    oset<int> T(3);                      // singleton
    rprint(T);              // should print 3

    oset<int> U(S);                      // copy of S
    oset<int> V(S);                      // copy of S

    oset<int> W; W = S;  rprint(W);      // 3 5 7

    S -= 4;                         // should be a no-op
    S -= 3;
    U -= 5;
    V -= 7;
    rprint(S);                       // 5 7
    rprint(U);                       // 3 7
    rprint(V);                       // 3 5

    oset<int> A;  ((A += 5) += 3) += 4;  rprint(A);       // 3 4 5
    oset<int> B;  ((B += 6) += 5) += 7;  rprint(B);       // 5 6 7

    oset<int> AuB(A);  AuB += B;  rprint(AuB);            // 3 4 5 6 7
    oset<int> AmB(A);  AmB -= B;  rprint(AmB);            // 3 4
    oset<int> AiB(A);  AiB *= B;  rprint(AiB);            // 5
}
