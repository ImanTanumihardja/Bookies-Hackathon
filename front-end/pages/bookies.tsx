import { Box, Grid, GridItem, useToast } from '@chakra-ui/react';
import SectionHero from 'components/elements/SectionHero';
import { Default } from 'components/layouts/Default';
import { SearchBookies, CreateBookie, BookiesList } from 'components/templates/bookies';
import { NextPage } from 'next';

const BookiesPage: NextPage = (props) => {

  return (
    <Default pageName="Bookies">
      <Box className="space-y-4">
        <SectionHero title="Bookies" description="Explore bookies and make brackets to win prizes."></SectionHero>
        <Grid gap={3}>
          <GridItem rowSpan={2} colSpan={5}>
            <CreateBookie />
          </GridItem>
          <GridItem colSpan={3} rowSpan={2}>
            <SearchBookies />
          </GridItem>
          <GridItem colSpan={2} rowSpan={10}>
            <BookiesList />
          </GridItem>
        </Grid>
      </Box>
    </Default>
  );
};

export default BookiesPage;
