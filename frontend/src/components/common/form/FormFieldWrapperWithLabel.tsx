import React from 'react';
import { Col, Form, Row } from 'react-bootstrap';
import RequireCaution from './RequireCaution';
import style from './FormFieldWrapperWithLabel.module.scss';

type Props = {
  label: string;
  required?: boolean;
  formFieldId?: string;
  children: React.ReactNode;
};

export default (props: Props) => {
  const { required, label, formFieldId, children } = props;

  return (
    <Form.Group as={Row} className={style['form-field']}>
      <Form.Label column sm={2} htmlFor={formFieldId}>
        {label}
        &nbsp;
        {required && <RequireCaution />}
      </Form.Label>
      <Col sm={10}>{children}</Col>
    </Form.Group>
  );
};
