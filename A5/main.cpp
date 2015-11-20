#include "lib/oset.hpp"
#include <iostream>
using std::cout;
using std::endl;
using std::flush;

int main() {
    // Some simple testing code.  You'll need a lot more.

    oset S;     // empty set
    S += 3;     // now should contain 3

    cout << S[3] << " ";            // should print 1 (true) : 3 is in S
    S += 3;                         // should be a no-op
    cout << S[5] << endl;           // should print 0 (false) : 5 not in S

    (S += 5) += 7;
    print(S);                       // should print 3 5 7

    oset T(3);                      // singleton
    print(T);                       // should print 3

    oset U(S);                      // copy of S
    oset V(S);                      // copy of S

    oset W;  W = S;  print(W);      // 3 5 7

    S -= 4;                         // should be a no-op
    S -= 3;
    U -= 5;
    V -= 7;
    print(S);                       // 5 7
    print(U);                       // 3 7
    print(V);                       // 3 5

    oset A;  ((A += 5) += 3) += 4;  print(A);       // 3 4 5
    oset B;  ((B += 6) += 5) += 7;  print(B);       // 5 6 7

    oset AuB(A);  AuB += B;  print(AuB);            // 3 4 5 6 7
    oset AmB(A);  AmB -= B;  print(AmB);            // 3 4
    oset AiB(A);  AiB *= B;  print(AiB);            // 5
}
