module.exports = {
   TournamentInfo: {
    name: "Test Tournament",
    startDate: Math.trunc(Date.now() / 1000) + 60 * 1,
    endDate: Math.trunc(Date.now() / 1000) + 60 * 2,
    oracleAddress: "0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB",
    teamName: ["Netherlands", "USA", "Argentia", "Australia", "England", "Sengal", "France", "Poland"],
    numRounds: 3,
    gasLimit: 500000
  }
}