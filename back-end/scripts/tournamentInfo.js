teamNames = ["Netherlands", "USA", "Argentina", "Australia", "England", "Sengal", "France", "Poland"];
startDate = Math.trunc(Date.now() / 1000) + 60 * 1;

module.exports = {
  TournamentInfo: {
    eventID: 1,
    name: "2022 World Cup",
    startDate: startDate,
    teamNames: teamNames,
    gameDates: Array.from({ length: teamNames.length - 1 }, (_, i) => startDate + i * 60),
    numRounds: 3,
  }
}