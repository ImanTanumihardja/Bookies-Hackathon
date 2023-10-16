module.exports = {
   TournamentInfo: {
    name: "Test Tournament",
    startDate: Math.trunc(Date.now() / 1000) + 60 * 2,
    endDate: Math.trunc(Date.now() / 1000) + 60 * 3,
    oracleAddress: "0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB",
    teamName: ["Netherlands", "USA", "Argentina", "Australia", "England", "Sengal", "France", "Poland"],
    numRounds: 3,
    gasLimit: 500000
  }
}