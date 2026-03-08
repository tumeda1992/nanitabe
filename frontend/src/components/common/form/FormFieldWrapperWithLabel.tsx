import React from 'react';
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
    <div className={style['form-field']} style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem', marginBottom: '0.5rem' }}>
      <label htmlFor={formFieldId} style={{ minWidth: '8rem', paddingTop: '0.375rem', fontSize: '0.875rem', fontWeight: 500 }}>
        {label}
        &nbsp;
        {required && <RequireCaution />}
      </label>
      <div style={{ flex: 1 }}>{children}</div>
    </div>
  );
};
