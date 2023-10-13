import { Default } from 'components/layouts/Default';
import { NextPage } from 'next';
import { ITournaments, FindTournament, TournamentsList } from 'components/templates/tournaments';
import { useState } from 'react';
import SectionHero from 'components/elements/SectionHero';


const TournamentsPage: NextPage<ITournaments> = (props) => {
  const [tournamentFilter, setTournamentFilter] = useState('');
  const subProps: ITournaments = { tournamentFilter, setTournamentFilter };


  return (
    <Default pageName="Tournaments">
      <SectionHero
        title="Tournaments"
        description="Find your favorite tournaments to begin betting."
      ></SectionHero>
      <div>
        <br />
        <FindTournament {...subProps} />
        <br />
        <TournamentsList {...subProps} />
      </div>
    </Default>
  );
};

export default TournamentsPage;
