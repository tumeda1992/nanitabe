import type { ApolloError, FetchResult, MutationTuple } from '@apollo/client';

export type MutationCallbacks<Output> = {
  onCompleted?: (data: Output) => void;
  onError?: (error: ApolloError) => void;
};

export type ExecMutation<Input, Output> = (
  input: Input,
  callbacks?: MutationCallbacks<Output>,
) => Promise<FetchResult<Output>>;

type BuildMutationOption<Input> = {
  normalizeInput?: (input: Input) => Input;
  refetchQueries?: any[];
};

export const buildMutationExecutor = <Input = any, Output = any>(
  codegenMutationHook: () => MutationTuple<Output, any>,
  { normalizeInput, refetchQueries }: BuildMutationOption<Input> = {},
): [ExecMutation<Input, Output>, boolean, ApolloError | undefined] => {
  const [mutation, { loading: mutationLoading, error: mutationError }] = codegenMutationHook();
  const execMutation = async (
    input: Input,
    { onCompleted, onError }: MutationCallbacks<Output> = {},
  ) => {
    const normalizedInput = normalizeInput ? normalizeInput(input) : input;
    return mutation({
      variables: normalizedInput,
      refetchQueries,
      onCompleted: (data: Output) => {
        if (onCompleted) onCompleted(data);
      },
      onError: (error: ApolloError) => {
        console.error(error);
        if (onError) onError(error);
      },
    });
  };
  return [execMutation, mutationLoading, mutationError];
};
