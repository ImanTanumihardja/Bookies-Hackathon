module.exports = {
   TournamentInfo: {
    name: "2022 World Cup",
    startDate: Math.trunc(Date.now() / 1000) + 60 * 3.5,
    endDate: Math.trunc(Date.now() / 1000) + 60 * 4.5,
    oracleAddress: "0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884",
    collateralCurrencyAddress : "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
    teamName: ["Netherlands", "USA", "Argentina", "Australia", "England", "Sengal", "France", "Poland"],
    numRounds: 3,
    gasLimit: 500000
  }
}