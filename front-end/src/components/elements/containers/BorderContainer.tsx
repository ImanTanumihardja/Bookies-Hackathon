type Props = {
  children?: JSX.Element[] | JSX.Element;
  onClick?: () => void;
  className?: string;
};

const BorderContainer = ({ children, onClick, className }: Props) => {
  return (
    <div onClick={onClick} className={`rounded-lg p-6   bg-gray-800 transition-all ${className}`}>
      {children}
    </div>
  );
};

export default BorderContainer;
