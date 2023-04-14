pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux2.circom";

// Returns math.ceil(log2(a)). Assumes a > 0.
function log2(a) {
    if (a == 1) {
        return 0;
    }
    var n = 1;
    var r = 0;
    while (n < a) {
        n *= 2;
        r++;
    }
    return r;
}

template Num2BitsBE(n) {
    signal input in;
    signal output out[n];
    var lc1 = 0;

    var e2 = 1;
    for (var i = 0; i < n; i++) {
        var b = (n - 1) - i;
        out[b] <-- (in >> i) & 1;
        out[b] * (out[b] - 1 ) === 0;
        lc1 += out[b] * e2;
        e2 = e2 + e2;
    }

    lc1 === in;
}

template Bits2NumBE(n) {
    signal input in[n];
    signal output out;
    var lc1=0;

    var e2 = 1;
    for (var i = 0; i < n; i++) {
        lc1 += in[(n - 1) - i] * e2;
        e2 = e2 + e2;
    }

    lc1 ==> out;
}

template IsEqualIfEnabled(n) {
    signal input in[2][n];
    signal input enabled;
    signal output out;

    component isz[n];
    component and = MultiAND(n);

    for (var i = 0; i < n; i++) {
        isz[i] = IsZero();
        isz[i].in <== in[0][i] - in[1][i];
        and.in[i] <== isz[i].out;
    }
    
    out <== and.out * enabled;
}

template CalculateTotal(n) {
    signal input nums[n];
    signal output sum;

    signal sums[n];
    sums[0] <== nums[0];

    for (var i = 1; i < n; i++) {
        sums[i] <== sums[i - 1] + nums[i];
    }

    sum <== sums[n - 1];
}

/**
Packer

Packs a list of numbers, each of a specified bitwidth, into another list of numbers with a different bitwidth.

- inWidth: The bitwidth of each input number.
- inCount: The number of input numbers.
- outWidth: The bitwidth of each output number.
- outCount: The number of output numbers. (Should be inCount * inWidth / outWidth, rounded up.)
*/
template Packer(inWidth, inCount, outWidth, outCount) {
    signal input in[inCount];
    signal output out[outCount];

    var inBits = inCount * inWidth;
    var myOutCount = inBits \ outWidth;
    if (inBits % outWidth != 0) {
        myOutCount++;
    }
    assert(myOutCount == outCount);

    component expander[inCount];
    for (var i = 0; i < inCount; i++) {
        expander[i] = Num2BitsBE(inWidth);
        expander[i].in <== in[i];
    }

    component compressor[outCount];
    for (var i = 0; i < outCount; i++) {
        compressor[i] = Bits2NumBE(outWidth);
    }

    for(var i = 0; i < inBits; i++) {
        var oB = i % outWidth;
        var o = (i - oB) \ outWidth;

        var mB = i % inWidth;
        var m = (i - mB) \ inWidth;

        compressor[o].in[oB] <== expander[m].out[mB];
    }

    if (inBits % outWidth != 0) {
        var outExtra = inBits % outWidth;
        for(var i = outExtra; i < outWidth; i++) {
            compressor[outCount - 1].in[i] <== 0;
        }
    }

    for(var i = 0; i < outCount; i++) {
        out[i] <== compressor[i].out;
    }
}

/**
RemainderMod4

Calculates the remainder of a number divided by 4.

Construction Params:
- maxBits: The maximum number of bits the input can have.

IO Signals:
- in: The input number.
- out: The output remainder.

Assumptions:
- maxBits < log(p) - 1, where p is the modulus of the field. Note that this automatically implies val(in) >= 0.
**/
template RemainderMod4(maxBits) {
    signal input in;
    signal output out;

    component toBits = Num2Bits(maxBits);
    toBits.in <== in;
    out <== 2 * toBits.out[1] + toBits.out[0];
}
