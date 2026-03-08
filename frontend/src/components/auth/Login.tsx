'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { SubmitHandler, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import style from './Login.module.scss';
import FormFieldWrapperWithLabel from '../common/form/FormFieldWrapperWithLabel';
import useAuth from '../../features/auth/useAuth';
import type { Login } from '../../features/auth/useAuth';
import { WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK } from '../../app/calendar/week/[date]/consts';

export default (props) => {
  const { login, loginLoading, LoginSchema } = useAuth();
  const [loginResultMessage, setLoginResultMessage] = useState<string | null>(
    null,
  );
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    resolver: zodResolver(LoginSchema),
  });
  const onSubmit: SubmitHandler<Login> = async (input) => {
    await login(input, {
      onCompleted: async () => {
        setLoginResultMessage('ログインが成功しました');
        reset();
        window.location.href = WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK;
      },
      onError: async () => {
        setLoginResultMessage('ログインに失敗しました');
      },
    });
  };
  return (
    <div className={style['login']}>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className={style['login__title']}>ログイン</div>
        {loginResultMessage && (
          <div data-testid="loginResultMessage">{loginResultMessage}</div>
        )}
        <FormFieldWrapperWithLabel label="メールアドレス">
          <Input
            type="email"
            {...register('email')}
            data-testid="email"
          />
          {errors.email?.message && <p>{errors.email.message.toString()}</p>}
        </FormFieldWrapperWithLabel>
        <FormFieldWrapperWithLabel label="パスワード">
          <Input
            type="password"
            {...register('password')}
            data-testid="password"
          />
          {errors.password?.message && (
            <p>{errors.password.message.toString()}</p>
          )}
        </FormFieldWrapperWithLabel>
        <Button type="submit" disabled={loginLoading} data-testid="loginButton">
          ログイン
        </Button>
      </form>
    </div>
  );
};
