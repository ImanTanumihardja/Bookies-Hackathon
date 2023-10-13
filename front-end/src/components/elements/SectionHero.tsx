import { BorderContainer } from 'components/elements/containers';

type Props = {
  children?: JSX.Element[] | JSX.Element;
  title: string;
  description: string;
};

const SectionHero = ({ children, title, description }: Props) => {
  return (
    <BorderContainer className="space-y-2">
      <h1 className="font-display font-bold text-5xl">{title}</h1>
      <div>{description}</div>
      <div>{children}</div>
    </BorderContainer>
  );
};

export default SectionHero;
