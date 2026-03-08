'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useForm, SubmitHandler } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import useAuth from '../../features/auth/useAuth';
import type { Signup } from '../../features/auth/useAuth';
import style from './Signup.module.scss';
import FormFieldWrapperWithLabel from '../common/form/FormFieldWrapperWithLabel';

export default () => {
  const { signup, signupLoading, SignupSchema } = useAuth();
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    resolver: zodResolver(SignupSchema),
  });
  const onSubmit: SubmitHandler<Signup> = async (input) => {
    await signup(input, {
      onCompleted: async () => {
        window.alert('ユーザ登録が成功しました');
        reset();
      },
      onError: async () => {
        window.alert('ユーザ登録に失敗しました');
      },
    });
  };

  return (
    <div className={style['register-user']}>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className={style['register-user__title']}>ユーザ登録</div>
        <FormFieldWrapperWithLabel label="メールアドレス">
          <Input type="email" {...register('email')} />
          {errors.email?.message && <p>{errors.email.message.toString()}</p>}
        </FormFieldWrapperWithLabel>
        <FormFieldWrapperWithLabel label="パスワード">
          <Input type="password" {...register('password')} />
          {errors.password?.message && (
            <p>{errors.password.message.toString()}</p>
          )}
        </FormFieldWrapperWithLabel>
        <FormFieldWrapperWithLabel label="パスワード確認">
          <Input type="password" {...register('passwordConfirmation')} />
          {errors.passwordConfirmation?.message && (
            <p>{errors.passwordConfirmation.message.toString()}</p>
          )}
        </FormFieldWrapperWithLabel>
        <Button type="submit" disabled={signupLoading}>
          登録
        </Button>
      </form>
    </div>
  );
};
