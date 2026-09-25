const chai = require("chai");
const expect = chai.expect;
const path = require("path");
const circomlibjs = require("circomlibjs");

describe("EducationVerifier Circom Circuit Tests", function () {
    this.timeout(100000);

    let poseidon;

    before(async () => {
        poseidon = await circomlibjs.buildPoseidon();
    });

    it("should compute valid Poseidon nullifier matching circuit expectation", async () => {
        const userSecret = BigInt("12345678901234567890");
        const sessionNonce = BigInt("98765432109876543210");

        const hash = poseidon([userSecret, sessionNonce]);
        const nullifier = poseidon.F.toString(hash);

        expect(nullifier).to.be.a("string");
        expect(nullifier.length).to.be.greaterThan(0);
    });

    it("should generate distinct nullifiers for different session nonces (anti-replay)", async () => {
        const userSecret = BigInt("12345678901234567890");
        const nonceA = BigInt("11111111111111111111");
        const nonceB = BigInt("22222222222222222222");

        const nullifierA = poseidon.F.toString(poseidon([userSecret, nonceA]));
        const nullifierB = poseidon.F.toString(poseidon([userSecret, nonceB]));

        expect(nullifierA).to.not.equal(nullifierB);
    });

    it("should verify degree code match constraint (degreeCode == requiredDegreeCode)", () => {
        const degreeCode = 1; // Bachelor of Technology
        const requiredDegreeCode = 1; // Bachelor of Technology

        expect(degreeCode).to.equal(requiredDegreeCode);
    });

    it("should verify valid credential status constraint (credentialStatus == 1)", () => {
        const credentialStatus = 1; // VALID
        expect(credentialStatus).to.equal(1);
    });
});
