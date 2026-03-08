import React from 'react';

// Mock vaul Drawer for JSDOM test environment
// vaul uses pointer capture APIs not available in JSDOM

type DrawerProps = {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  children?: React.ReactNode;
  [key: string]: any;
};

const Root = ({ open, onOpenChange, children, ...props }: DrawerProps) => {
  return <div data-vaul-drawer-root data-open={open} {...props}>{children}</div>;
};

const Trigger = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

const Portal = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

const Overlay = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

const Content = ({
  open,
  children,
  ...props
}: {
  open?: boolean;
  children?: React.ReactNode;
  [key: string]: any;
}) => {
  return <div data-vaul-drawer-content {...props}>{children}</div>;
};

const Title = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

const Description = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

const Close = ({ children, ...props }: { children?: React.ReactNode; [key: string]: any }) => {
  return <div {...props}>{children}</div>;
};

export const Drawer = {
  Root,
  Trigger,
  Portal,
  Overlay,
  Content,
  Title,
  Description,
  Close,
};
