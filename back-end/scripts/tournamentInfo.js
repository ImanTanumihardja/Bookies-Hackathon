module.exports = {
   TournamentInfo: {
    name: "Test Tournament",
    startDate: Math.trunc(Date.now() / 1000) + 60 * 2,
    endDate: Math.trunc(Date.now() / 1000) + 60 * 3,
    oracleAddress: "0x263351499f82C107e540B01F0Ca959843e22464a",
    teamName: ["Netherlands", "USA", "Argentina", "Australia", "England", "Sengal", "France", "Poland"],
    numRounds: 3,
    gasLimit: 500000
  }
}